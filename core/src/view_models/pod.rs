use std::{collections::HashMap, sync::Arc};

use eyre::eyre;
use kube::Client;
use log::{debug, error};
use thiserror::Error;
use uniffi::Object;

use act_zero::*;

use crate::{
    cluster::ClusterId,
    kubernetes::{
        self,
        pod::{Pod, PodId},
    },
    task::{self, spawn_actor},
};

use super::global::GlobalViewModel;

#[derive(Error, Debug)]
pub enum PodError {
    #[error(transparent)]
    PodLoadError(eyre::Report),
}

#[derive(uniffi::Enum, Clone, Debug)]
pub enum PodLoadStatus {
    Initial,
    Loading,
    Loaded { pods: HashMap<PodId, Pod> },
    Error { error: String },
}

#[uniffi::export(callback_interface)]
pub trait PodViewModelCallback: Send + Sync + 'static {
    fn callback(&self, message: PodViewModelMessage);
}

#[derive(uniffi::Enum)]
pub enum PodViewModelMessage {
    LoadingPods,
    PodsLoaded { pods: Vec<Pod> },
    PodLoadingFailed { error: String },
}

#[derive(Object)]
pub struct RustPodViewModel {
    actor: Addr<PodViewModel>,
}

pub struct PodViewModel {
    addr: WeakAddr<Self>,
    watcher: Addr<Watcher>,
    pods: PodLoadStatus,
    responder: Option<Box<dyn PodViewModelCallback>>,
}

#[uniffi::export(async_runtime = "tokio")]
impl RustPodViewModel {
    #[uniffi::constructor]
    pub fn new() -> Arc<Self> {
        Arc::new(Self {
            actor: spawn_actor(PodViewModel::new()),
        })
    }

    pub fn pods(self: Arc<Self>) -> Vec<Pod> {
        debug!("getting pods blocking");
        let actor = self.actor.clone();

        task::block_on(async move {
            match call!(actor.pods()).await {
                Ok(Some(pods)) => pods.into_values().collect(),
                _ => vec![],
            }
        })
    }

    pub async fn add_callback_listener(&self, responder: Box<dyn PodViewModelCallback>) {
        debug!("pod view model callback listener added");
        let _ = call!(self.actor.add_callback_listener(responder)).await;
    }

    pub async fn start_watcher(&self, selected_cluster: ClusterId) {
        let _ = call!(self.actor.start_watcher(selected_cluster)).await;
    }

    pub async fn stop_watcher(&self) {
        let _ = call!(self.actor.stop_watcher()).await;
    }

    pub async fn fetch_pods(&self, selected_cluster: ClusterId) {
        let _ = call!(self.actor.notify_and_load_pods(selected_cluster)).await;
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

            pods: PodLoadStatus::Initial,
            responder: None,
        }
    }

    pub async fn pods(&self) -> ActorResult<Option<HashMap<PodId, Pod>>> {
        match &self.pods {
            PodLoadStatus::Loaded { pods } => Produces::ok(Some(pods.clone())),
            _ => Produces::ok(None),
        }
    }

    pub async fn update_pod(&mut self, pod: Pod) -> Option<Pod> {
        match &mut self.pods {
            PodLoadStatus::Loaded { pods } => pods.insert(pod.id.clone(), pod),
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
        self.pods = PodLoadStatus::Loaded { pods: pods_map };

        // notify ui
        self.notify_pods_loaded().await;

        Produces::ok(())
    }

    pub async fn start_watcher(&mut self, selected_cluster: ClusterId) {
        self.watcher = spawn_actor(Watcher::new(selected_cluster, self.addr.clone()));
        send!(self.watcher.start_watcher());
    }

    pub async fn stop_watcher(&mut self) {
        self.watcher = Default::default();
    }

    pub async fn applied(&mut self, pod: Pod) -> ActorResult<()> {
        if let Some(ref pods) = call!(self.addr.pods()).await? {
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
        let PodLoadStatus::Loaded { pods } = &mut self.pods else {
            return Produces::ok(());
        };

        if pods.remove(&pod.id).is_some() {
            // only notify if pod existed before
            self.notify_pods_loaded().await;
        }

        Produces::ok(())
    }

    async fn notify_pods_loading(&self) {
        self.callback(PodViewModelMessage::LoadingPods).await
    }

    async fn notify_pods_loaded(&self) {
        if let PodLoadStatus::Loaded { pods } = &self.pods {
            self.callback(PodViewModelMessage::PodsLoaded {
                pods: pods.values().cloned().collect(),
            })
            .await
        }
    }
}

impl From<PodError> for PodViewModelMessage {
    fn from(error: PodError) -> Self {
        match error {
            PodError::PodLoadError(e) => PodViewModelMessage::PodLoadingFailed {
                error: e.to_string(),
            },
        }
    }
}

#[async_trait::async_trait]
impl Actor for PodViewModel {
    async fn started(&mut self, addr: Addr<Self>) -> ActorResult<()> {
        self.addr = addr.downgrade();
        Produces::ok(())
    }

    async fn error(&mut self, error: ActorError) -> bool {
        error!("PodViewModel Actor Error: {error:?}");

        if let Some(error) = error.downcast::<PodError>().ok().map(|e| *e) {
            self.callback(error.into()).await
        } else {
            self.callback(PodViewModelMessage::PodLoadingFailed {
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
    model_actor: WeakAddr<PodViewModel>,
}

impl Watcher {
    fn new(selected_cluster: ClusterId, addr: WeakAddr<PodViewModel>) -> Self {
        Self {
            selected_cluster,
            model_actor: addr,
        }
    }

    async fn start_watcher(&self) -> ActorResult<()> {
        GlobalViewModel::check_and_load_client(&self.selected_cluster).await?;

        let client = GlobalViewModel::global()
            .read()
            .get_cluster_client(&self.selected_cluster)
            .ok_or_else(|| eyre!("client not found"))?;

        kubernetes::pod::watch(
            self.model_actor.clone(),
            self.selected_cluster.clone(),
            client,
        )
        .await?;

        Produces::ok(())
    }
}
