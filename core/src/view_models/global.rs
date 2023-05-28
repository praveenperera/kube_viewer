use std::collections::HashMap;

use act_zero::*;
use kube::Client;
use once_cell::sync::OnceCell;
use parking_lot::RwLock;

use crate::{
    cluster::{Cluster, ClusterId, Clusters},
    env::Env,
    kubernetes::client_store::ClientStore,
    task,
};

static INSTANCE: OnceCell<RwLock<GlobalViewModel>> = OnceCell::new();

impl GlobalViewModel {
    pub fn global() -> &'static RwLock<GlobalViewModel> {
        INSTANCE.get_or_init(|| RwLock::new(GlobalViewModel::new()))
    }
}

pub trait GloabalViewModelCallback: Send + Sync + 'static {
    fn callback(&self, message: GlobalViewModelMessage);
}

pub enum GlobalViewModelMessage {
    LoadingClient,
    ClientLoaded,
    ClientLoadError { error: String },
}

pub struct RustGlobalViewModel;

pub struct GlobalViewModel {
    pub clusters: Option<Clusters>,
    pub client_store: ClientStore,

    pub worker: Addr<Worker>,
}

impl Default for RustGlobalViewModel {
    fn default() -> Self {
        Self::new()
    }
}

impl Default for GlobalViewModel {
    fn default() -> Self {
        Self::new()
    }
}

impl RustGlobalViewModel {
    pub fn new() -> Self {
        Self
    }

    pub fn inner(&self) -> &RwLock<GlobalViewModel> {
        GlobalViewModel::global()
    }

    pub fn add_callback_listener(&self, responder: Box<dyn GloabalViewModelCallback>) {
        let addr = GlobalViewModel::global().read().worker.clone();
        task::spawn(async move { send!(addr.add_callback_listener(responder)) });
    }
}

#[uniffi::export]
impl RustGlobalViewModel {
    pub fn clusters(&self) -> HashMap<ClusterId, Cluster> {
        self.inner().read().clusters()
    }

    pub fn load_client(&self, cluster_id: ClusterId) {
        let worker = self.inner().read().worker.clone();
        send!(worker.load_client(cluster_id));
    }
}

impl GlobalViewModel {
    pub fn new() -> Self {
        //TODO: set manually in code for now
        std::env::set_var("RUST_LOG", "kube_viewer=debug");

        // one time init
        env_logger::init();

        // init env
        let _ = Env::global();
        let clusters = Clusters::try_new().ok();
        let client_store = ClientStore::new();

        let worker = task::spawn_actor(Worker::new());

        Self {
            clusters,
            client_store,
            worker,
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
    responder: Option<Box<dyn GloabalViewModelCallback>>,
}

impl Default for Worker {
    fn default() -> Self {
        Self::new()
    }
}

impl Worker {
    pub fn new() -> Self {
        Self {
            addr: Default::default(),
            responder: None,
        }
    }

    pub fn callback(&self, msg: GlobalViewModelMessage) {
        if let Some(responder) = self.responder.as_ref() {
            responder.callback(msg);
        }
    }

    async fn add_callback_listener(
        &mut self,
        responder: Box<dyn GloabalViewModelCallback>,
    ) -> ActorResult<()> {
        self.responder = Some(responder);
        Produces::ok(())
    }

    pub async fn load_client(&self, cluster_id: ClusterId) -> ActorResult<()> {
        self.callback(GlobalViewModelMessage::LoadingClient);

        let client_store_worker = GlobalViewModel::global().read().client_store.worker.clone();

        match call!(client_store_worker.load_client(cluster_id)).await {
            Ok(_) => self.callback(GlobalViewModelMessage::ClientLoaded),
            Err(error) => self.callback(GlobalViewModelMessage::ClientLoadError {
                error: error.to_string(),
            }),
        }

        Produces::ok(())
    }
}

#[async_trait::async_trait]
impl Actor for Worker {
    async fn started(&mut self, addr: Addr<Self>) -> ActorResult<()> {
        self.addr = addr.downgrade();

        GlobalViewModel::global().write().worker = addr;

        Produces::ok(())
    }

    async fn error(&mut self, error: ActorError) -> bool {
        log::error!("GlobalViewModel Actor Error: {error:?}");

        false
    }
}
