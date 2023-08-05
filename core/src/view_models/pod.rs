use std::{collections::HashMap, sync::Arc, time::Duration};

use eyre::eyre;
use fake::{Fake, Faker};
use kube::Client;
use log::{debug, error, warn};
use parking_lot::RwLock;
use thiserror::Error;
use tokio::{task::JoinHandle, time};
use uniffi::Object;

use act_zero::*;

use crate::{
    cluster::ClusterId,
    kubernetes::{
        self,
        pod::{Pod, PodId},
    },
    task::{self, spawn_actor},
    LoadStatus,
};

use super::global::GlobalViewModel;

#[derive(Error, Debug)]
pub enum PodError {
    #[error(transparent)]
    PodLoadError(eyre::Report),
}

#[uniffi::export(callback_interface)]
pub trait PodViewModelCallback: Send + Sync + 'static {
    fn callback(&self, message: PodViewModelMessage);
}

#[derive(uniffi::Enum)]
pub enum PodViewModelMessage {
    Loading,
    Loaded { pods: Vec<Pod> },
    LoadingFailed { error: String },
}

#[derive(Object)]
pub struct RustPodViewModel {
    actor: RwLock<Addr<PodViewModel>>,
}

pub struct PodViewModel {
    addr: Addr<Self>,
    watcher: Addr<Watcher>,
    pods: LoadStatus<HashMap<PodId, Pod>, String>,
    responder: Option<Box<dyn PodViewModelCallback>>,
}

#[uniffi::export(async_runtime = "tokio")]
impl RustPodViewModel {
    #[uniffi::constructor]
    pub fn new() -> Arc<Self> {
        Arc::new(Self {
            actor: RwLock::new(Default::default()),
        })
    }

    #[uniffi::constructor]
    pub fn preview() -> Arc<Self> {
        Arc::new(Self {
            actor: RwLock::new(Default::default()),
        })
    }

    pub fn pods(self: Arc<Self>) -> Vec<Pod> {
        warn!("getting pods blocking");
        let actor = self.actor.read().clone();

        task::block_on(async move {
            match call!(actor.pods()).await {
                Ok(Some(pods)) => pods.into_values().collect(),
                _ => vec![],
            }
        })
    }

    pub async fn add_callback_listener(&self, responder: Box<dyn PodViewModelCallback>) {
        debug!("pod view model callback listener added");
        {
            let mut actor = self.actor.write();
            *actor = spawn_actor(PodViewModel::new());
        }

        let actor = self.actor.read().clone();
        call!(actor.add_callback_listener(responder))
            .await
            .expect("failed to add callback listener");
    }

    pub async fn start_watcher(&self, selected_cluster: ClusterId) {
        debug!("starting pod watcher for cluster: {selected_cluster:?}");
        let actor = self.actor.read().clone();

        call!(actor.start_watcher(selected_cluster))
            .await
            .expect("failed to start pod watcher");
    }

    pub async fn stop_watcher(&self) {
        debug!("stopping pod watcher");
        let actor = self.actor.read().clone();
        call!(actor.stop_watcher())
            .await
            .expect("failed to stop pod watcher");
    }

    pub async fn fetch_pods(&self, selected_cluster: ClusterId) {
        debug!("fetching pods for cluster: {selected_cluster:?}");
        let actor = self.actor.read().clone();

        if let Err(error) = call!(actor.notify_and_load_pods(selected_cluster)).await {
            error!("failed to fetch pods: {error}");
        }
    }
}

impl Default for PodViewModel {
    fn default() -> Self {
        Self::new()
    }
}

impl PodViewModel {
    pub fn new() -> Self {
        Self {
            addr: Default::default(),
            watcher: Default::default(),

            pods: LoadStatus::Initial,
            responder: None,
        }
    }

    pub fn preview() -> Self {
        Self {
            addr: Default::default(),
            watcher: Default::default(),
            pods: LoadStatus::Loaded(
                (0..16)
                    .map(|_| Faker.fake::<Pod>())
                    .map(|pod| (pod.id.clone(), pod))
                    .collect(),
            ),
            responder: None,
        }
    }

    pub async fn pods(&self) -> ActorResult<Option<HashMap<PodId, Pod>>> {
        match &self.pods {
            LoadStatus::Loaded(pods) => Produces::ok(Some(pods.clone())),
            _ => Produces::ok(None),
        }
    }

    pub async fn update_pod(&mut self, pod: Pod) -> Option<Pod> {
        match &mut self.pods {
            LoadStatus::Loaded(pods) => pods.insert(pod.id.clone(), pod),
            _ => None,
        }
    }

    pub async fn add_callback_listener(&mut self, responder: Box<dyn PodViewModelCallback>) {
        self.responder = Some(responder);
    }

    pub async fn callback(&self, msg: PodViewModelMessage) {
        self.responder
            .as_ref()
            .expect("pod callback called before init")
            .callback(msg);
    }

    pub async fn notify_and_load_pods(&mut self, selected_cluster: ClusterId) -> ActorResult<()> {
        debug!("notifying and loading pods");

        // notify UI that pods are going to be loaded
        self.notify_pods_loading().await;

        // handle loading pods and notifying its done
        self.load_pods(selected_cluster).await?;

        Produces::ok(())
    }

    pub async fn load_pods(&mut self, selected_cluster: ClusterId) -> ActorResult<()> {
        // TODO: handle error
        GlobalViewModel::check_and_load_client(&selected_cluster).await?;

        let client: Client = GlobalViewModel::global()
            .read()
            .get_cluster_client(&selected_cluster)
            .ok_or_else(|| eyre!("client not found"))?;

        // fetch pods
        let pods_map = kubernetes::pod::get_all(client).await?;

        // save in model
        self.pods = LoadStatus::Loaded(pods_map);

        // notify ui
        self.notify_pods_loaded().await;

        Produces::ok(())
    }

    pub async fn start_watcher(&mut self, selected_cluster: ClusterId) {
        // create watcher actor
        self.watcher = spawn_actor(Watcher::new(selected_cluster, self.addr.clone()));

        // start watcher
        send!(self.watcher.start_watcher());

        // start refresh on interval
        send!(self.watcher.refresh_on_interval());
    }

    pub async fn stop_watcher(&mut self) -> ActorResult<()> {
        std::mem::take(&mut self.watcher);
        Produces::ok(())
    }

    pub async fn applied(&mut self, pod: Pod) -> ActorResult<()> {
        debug!("pod applied: {:?}", pod.id);

        if let Produces::Value(Some(ref pods)) = self.pods().await? {
            if let Some(existing_pod) = pods.get(&pod.id) {
                if existing_pod == &pod {
                    debug!("same pod already exists, ignoring");
                    return Produces::ok(());
                }
            }
        };

        // update existing pod
        self.update_pod(pod).await;

        // notify pods updated
        self.notify_pods_loaded().await;

        Produces::ok(())
    }

    pub async fn deleted(&mut self, pod: Pod) -> ActorResult<()> {
        debug!("pod deleted: {:?}", pod.id);

        let LoadStatus::Loaded(pods) = &mut self.pods else {
            return Produces::ok(());
        };

        debug!("removing pod: {:?}", pod.id);
        if pods.remove(&pod.id).is_some() {
            // only notify if pod existed before
            self.notify_pods_loaded().await;
        } else {
            debug!("pod not found: {:?}", pod.id);
        }

        Produces::ok(())
    }

    async fn notify_pods_loading(&self) {
        self.callback(PodViewModelMessage::Loading).await
    }

    async fn notify_pods_loaded(&self) {
        if let LoadStatus::Loaded(pods) = &self.pods {
            debug!("notifying pods loaded");

            self.callback(PodViewModelMessage::Loaded {
                pods: pods.values().cloned().collect(),
            })
            .await
        }
    }
}

impl From<PodError> for PodViewModelMessage {
    fn from(error: PodError) -> Self {
        match error {
            PodError::PodLoadError(e) => PodViewModelMessage::LoadingFailed {
                error: e.to_string(),
            },
        }
    }
}

#[async_trait::async_trait]
impl Actor for PodViewModel {
    async fn started(&mut self, addr: Addr<Self>) -> ActorResult<()> {
        self.addr = addr;
        Produces::ok(())
    }

    async fn error(&mut self, error: ActorError) -> bool {
        error!("PodViewModel Actor Error: {error:?}");

        if let Some(error) = error.downcast::<PodError>().ok().map(|e| *e) {
            self.callback(error.into()).await
        } else {
            self.callback(PodViewModelMessage::LoadingFailed {
                error: "Unknown error, please see logs".to_string(),
            })
            .await
        };

        false
    }
}

impl Actor for Watcher {}
pub struct Watcher {
    selected_cluster: ClusterId,
    model_actor: Addr<PodViewModel>,
    tasks: Vec<JoinHandle<()>>,
}

impl Watcher {
    fn new(selected_cluster: ClusterId, addr: Addr<PodViewModel>) -> Self {
        Self {
            selected_cluster,
            model_actor: addr,
            tasks: Vec::with_capacity(2),
        }
    }

    async fn start_watcher(&mut self) -> ActorResult<()> {
        GlobalViewModel::check_and_load_client(&self.selected_cluster).await?;

        let client = GlobalViewModel::global()
            .read()
            .get_cluster_client(&self.selected_cluster)
            .ok_or_else(|| eyre!("client not found"))?;

        let model_actor = self.model_actor.clone();
        let selected_cluster = self.selected_cluster.clone();

        let task = task::spawn(async move {
            kubernetes::pod::watch(model_actor, selected_cluster, client)
                .await
                .expect("pod watcher failed to start");
        });

        self.tasks.push(task);

        Produces::ok(())
    }

    async fn refresh_on_interval(&mut self) {
        let model_actor = self.model_actor.clone();
        let selected_cluster = self.selected_cluster.clone();

        let task = tokio::spawn(async move {
            let mut interval = time::interval(Duration::from_secs(60));
            interval.tick().await;

            loop {
                interval.tick().await;
                debug!("60 seconds past, loading pods");
                send!(model_actor.load_pods(selected_cluster.clone()));
            }
        });

        self.tasks.push(task);
    }
}

impl Drop for Watcher {
    fn drop(&mut self) {
        debug!("dropping pod watcher, aborting all tasks");
        for task in self.tasks.iter() {
            task.abort();
        }
    }
}
