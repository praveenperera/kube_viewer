use std::{
    collections::{HashMap, VecDeque},
    sync::Arc,
};

use act_zero::*;
use eyre::Result;
use kube::Client;
use log::debug;
use once_cell::sync::OnceCell;
use parking_lot::RwLock;

use crate::{
    cluster::{Cluster, ClusterId, Clusters},
    env::Env,
    kubernetes::{client_store::ClientStore, kube_config::KubeConfigWatcher},
    task, SimpleLoadStatus,
};

static INSTANCE: OnceCell<RwLock<GlobalViewModel>> = OnceCell::new();

impl GlobalViewModel {
    pub fn global() -> &'static RwLock<GlobalViewModel> {
        INSTANCE.get_or_init(|| RwLock::new(GlobalViewModel::new()))
    }

    pub async fn check_and_load_client(cluster_id: &ClusterId) -> Result<()> {
        debug!("checking and loading client for cluster {:?}", cluster_id);

        if !GlobalViewModel::global()
            .read()
            .client_store
            .contains_client(cluster_id)
        {
            debug!("loading client for cluster {:?}", cluster_id);
            let client_worker = GlobalViewModel::global().read().worker.clone();
            call!(client_worker.load_client(cluster_id.clone())).await?;
        }

        Ok(())
    }
}

#[uniffi::export(callback_interface)]
pub trait GlobalViewModelCallback: Send + Sync + 'static {
    fn callback(&self, message: GlobalViewModelMessage);
}

#[derive(uniffi::Enum)]
pub enum GlobalViewModelMessage {
    RefreshClusters,
    ClustersLoaded {
        clusters: HashMap<ClusterId, Cluster>,
    },
    LoadingClient,
    ClientLoaded,
    ClientLoadError {
        error: String,
    },
}

#[derive(uniffi::Object)]
pub struct RustGlobalViewModel;

pub struct GlobalViewModel {
    pub clusters: Option<Clusters>,
    pub client_store: ClientStore,
    pub worker: Addr<Worker>,
}

impl Default for GlobalViewModel {
    fn default() -> Self {
        Self::new()
    }
}

impl RustGlobalViewModel {
    pub fn inner(&self) -> &RwLock<GlobalViewModel> {
        GlobalViewModel::global()
    }
}

#[uniffi::export(async_runtime = "tokio")]
impl RustGlobalViewModel {
    #[uniffi::constructor]
    pub fn new() -> Arc<Self> {
        Arc::new(Self)
    }

    pub async fn add_callback_listener(&self, responder: Box<dyn GlobalViewModelCallback>) {
        let worker = task::spawn_actor(Worker::new(self.inner().read().client_store.clone()));
        GlobalViewModel::global().write().worker = worker.clone();

        let _ = call!(worker.add_callback_listener(responder)).await;
    }

    pub fn clusters(&self) -> HashMap<ClusterId, Cluster> {
        self.inner().read().clusters()
    }

    pub fn load_client(&self, cluster_id: ClusterId) {
        let worker = self.inner().read().worker.clone();
        send!(worker.load_client(cluster_id));
    }
}

fn init_logging() {
    use env_logger::Builder;
    use log::LevelFilter;

    let mut builder = Builder::new();
    builder
        .parse_env("RUST_LOG")
        .filter_module("kube_viewer::timestamps", LevelFilter::Info)
        .filter_module("kube_viewer::kubernetes::pod_uniffi", LevelFilter::Info);

    builder.init()
}

impl GlobalViewModel {
    pub fn new() -> Self {
        //TODO: set manually in code for now
        std::env::set_var("RUST_LOG", "kube_viewer=debug");

        // one time init
        init_logging();

        // init env
        let _ = Env::global();
        let clusters = Clusters::try_new().ok();

        // Create a background thread which checks for deadlocks every 10s
        // TODO: FIX BEFORE RELEASE: remove deadlock detection
        use std::thread;
        thread::spawn(move || loop {
            thread::sleep(std::time::Duration::from_secs(2));
            let deadlocks = parking_lot::deadlock::check_deadlock();
            if deadlocks.is_empty() {
                continue;
            }

            println!("{} deadlocks detected", deadlocks.len());
            for (i, threads) in deadlocks.iter().enumerate() {
                println!("Deadlock #{}", i);
                for t in threads {
                    println!("Thread Id {:#?}", t.thread_id());
                    println!("{:#?}", t.backtrace());
                }
            }
        });

        Self {
            clusters,
            client_store: ClientStore::new(),
            worker: Default::default(),
        }
    }

    pub fn clusters(&self) -> HashMap<ClusterId, Cluster> {
        self.clusters
            .as_ref()
            .map(|clusters| clusters.clusters_map.clone())
            .unwrap_or_default()
    }

    pub fn get_cluster(&self, cluster_id: &ClusterId) -> Option<Cluster> {
        let clusters = self.clusters.as_ref()?;
        clusters.get_cluster(cluster_id)
    }

    pub fn get_cluster_client(&self, cluster_id: &ClusterId) -> Option<Client> {
        self.client_store.get_cluster_client(cluster_id)
    }
}

pub struct Worker {
    addr: WeakAddr<Self>,
    client_store: ClientStore,
    kube_config_watcher: Addr<KubeConfigWatcher>,
    responder: Option<Box<dyn GlobalViewModelCallback>>,
    responder_queue: VecDeque<GlobalViewModelMessage>,
}

impl Worker {
    pub fn new(client_store: ClientStore) -> Self {
        Self {
            addr: Default::default(),
            client_store,
            kube_config_watcher: Default::default(),
            responder: None,
            responder_queue: VecDeque::new(),
        }
    }

    pub fn callback(&mut self, msg: GlobalViewModelMessage) {
        if let Some(responder) = self.responder.as_ref() {
            responder.callback(msg);
        } else {
            log::warn!("no responder set for global view model worker, adding to queue");
            self.responder_queue.push_back(msg);
        }
    }

    async fn add_callback_listener(
        &mut self,
        responder: Box<dyn GlobalViewModelCallback>,
    ) -> ActorResult<()> {
        self.responder = Some(responder);
        self.client_store.start_worker().await;

        while let Some(msg) = self.responder_queue.pop_front() {
            self.callback(msg);
        }

        Produces::ok(())
    }

    pub async fn start_new_kube_config_watcher(&mut self) -> ActorResult<()> {
        debug!("starting new kube config watch");

        let kube_config_watcher = KubeConfigWatcher::new(self.addr.clone());
        self.kube_config_watcher = task::spawn_actor(kube_config_watcher);

        Produces::ok(())
    }

    pub async fn reload_clusters(&mut self) -> ActorResult<()> {
        debug!("reloading clusters");

        let clusters = Clusters::try_new()?;
        GlobalViewModel::global().write().clusters = Some(clusters.clone());

        self.callback(GlobalViewModelMessage::ClustersLoaded {
            clusters: clusters.clusters_map,
        });

        Produces::ok(())
    }

    pub async fn load_client(&mut self, cluster_id: ClusterId) -> ActorResult<()> {
        debug!("loading client for cluster: {}", &cluster_id.raw_value);
        self.callback(GlobalViewModelMessage::LoadingClient);

        match self.client_store.load_client(cluster_id.clone()).await {
            Ok(_) => {
                self.callback(GlobalViewModelMessage::ClientLoaded);

                if let Some(cluster) = GlobalViewModel::global()
                    .write()
                    .clusters
                    .as_mut()
                    .and_then(|clusters| clusters.clusters_map.get_mut(&cluster_id))
                {
                    debug!(
                        "client loaded for cluster: {}, load_status: {:?}",
                        &cluster_id.raw_value, cluster.load_status
                    );

                    if !matches!(cluster.load_status, SimpleLoadStatus::Loaded) {
                        cluster.load_status = SimpleLoadStatus::Loaded;

                        self.callback(GlobalViewModelMessage::RefreshClusters);
                    }
                }
            }

            Err(error) => {
                log::warn!(
                    "client loaded erorr for: {:?}, error: {:?}",
                    cluster_id,
                    error
                );

                self.callback(GlobalViewModelMessage::ClientLoadError {
                    error: error.to_string(),
                });

                if let Some(cluster) = GlobalViewModel::global()
                    .write()
                    .clusters
                    .as_mut()
                    .and_then(|clusters| clusters.clusters_map.get_mut(&cluster_id))
                {
                    cluster.load_status = SimpleLoadStatus::Error {
                        error: error.to_string(),
                    };

                    self.callback(GlobalViewModelMessage::RefreshClusters);
                };
            }
        }

        Produces::ok(())
    }
}

#[async_trait::async_trait]
impl Actor for Worker {
    async fn started(&mut self, addr: Addr<Self>) -> ActorResult<()> {
        self.addr = addr.downgrade();

        GlobalViewModel::global().write().worker = addr;
        send!(self.addr.start_new_kube_config_watcher());

        Produces::ok(())
    }

    async fn error(&mut self, error: ActorError) -> bool {
        log::error!("GlobalViewModel Actor Error: {error:?}");
        false
    }
}
