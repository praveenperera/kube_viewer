use std::{borrow::Cow, collections::HashMap, sync::Arc, time::Duration};

use k8s_openapi::api::core::v1::Pod as K8sPod;

use either::Either;
use eyre::eyre;
use fake::{Fake, Faker};
use futures::{stream::FuturesUnordered, StreamExt};
use kube::{core::Status, Client};
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

    #[error("pod {0} not found for delete")]
    PodNotFoundForDelete(PodId),

    #[error("Unable to delete pod {0}: {1}")]
    PodDeleteError(PodId, kube::Error),
}

impl From<kubernetes::pod::Error> for PodError {
    fn from(error: kubernetes::pod::Error) -> Self {
        match error {
            kubernetes::pod::Error::DeleteError(pod_id, error) => {
                PodError::PodDeleteError(pod_id, error)
            }
        }
    }
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

    ToastWarningMessage { message: String },
    ToastErrorMessage { message: String },
}

#[derive(Object)]
pub struct RustPodViewModel {
    actor: RwLock<Addr<PodViewModel>>,
}

pub struct PodViewModel {
    addr: Addr<Self>,
    search: String,
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

    pub fn set_search(self: Arc<Self>, search: String) {
        let actor = self.actor.read().clone();
        send!(actor.set_search(search));
    }

    pub async fn delete_pod(self: Arc<Self>, selected_cluster: ClusterId, pod_id: PodId) {
        let actor = self.actor.read().clone();
        let _ = call!(actor.delete_pod(selected_cluster, pod_id)).await;
    }

    pub async fn delete_pods(self: Arc<Self>, selected_cluster: ClusterId, pod_ids: Vec<PodId>) {
        let actor = self.actor.read().clone();
        let _ = call!(actor.delete_pods(selected_cluster, pod_ids)).await;
    }

    pub async fn initialize_model_with_responder(&self, responder: Box<dyn PodViewModelCallback>) {
        // only initialize once
        let actor = self.actor.read().clone();
        if call!(actor.is_started()).await.is_ok() {
            debug!("pod view model already initialized");
            return;
        }

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

            search: String::new(),
            pods: LoadStatus::Initial,
            responder: None,
        }
    }

    pub fn preview() -> Self {
        Self {
            addr: Default::default(),
            watcher: Default::default(),
            search: String::new(),
            pods: LoadStatus::Loaded(
                (0..16)
                    .map(|_| Faker.fake::<Pod>())
                    .map(|pod| (pod.id.clone(), pod))
                    .collect(),
            ),
            responder: None,
        }
    }

    pub async fn set_search(&mut self, search: String) {
        self.search = search;
        self.notify_pods_loaded().await;
    }

    pub async fn is_started(&self) -> ActorResult<()> {
        Produces::ok(())
    }

    fn filtered_pods_iter(&self) -> Option<impl Iterator<Item = (&PodId, &Pod)>> {
        match &self.pods {
            LoadStatus::Loaded(pods) => {
                let pods = pods.iter().filter(|(_, pod)| {
                    if self.search.is_empty() {
                        return true;
                    }

                    pod.id.as_ref().contains(&self.search) || pod.name.contains(&self.search)
                });

                Some(pods)
            }
            _ => None,
        }
    }

    pub fn pods_filtered_vec(&self) -> Option<Vec<Pod>> {
        let pods: Vec<_> = self
            .filtered_pods_iter()?
            .map(|(_, pod)| pod.clone())
            .collect::<Vec<_>>();

        Some(pods)
    }

    pub async fn pods(&self) -> ActorResult<Option<HashMap<PodId, Pod>>> {
        match self.filtered_pods_iter() {
            Some(pods_iter) => {
                let pods = pods_iter.map(|(k, v)| (k.clone(), v.clone())).collect();
                Produces::ok(Some(pods))
            }
            None => Produces::ok(None),
        }
    }

    pub async fn update_pod(&mut self, pod: Pod) -> Option<Pod> {
        match &mut self.pods {
            LoadStatus::Loaded(pods) => pods.insert(pod.id.clone(), pod),
            _ => None,
        }
    }

    pub async fn delete_pod(
        &mut self,
        selected_cluster: ClusterId,
        pod_id: impl Into<Cow<'_, PodId>>,
    ) -> ActorResult<()> {
        let pod_id: Cow<'_, PodId> = pod_id.into();
        let pod_id = pod_id.as_ref();

        debug!("deleting pod: {:?}", pod_id);
        let LoadStatus::Loaded(pods) = &self.pods else {
            return Err(eyre::eyre!("pods not loaded").into());
        };

        let pod = pods
            .get(pod_id)
            .cloned()
            .ok_or_else(|| PodError::PodNotFoundForDelete(pod_id.clone()))?;

        let client = GlobalViewModel::global()
            .read()
            .get_cluster_client(&selected_cluster)
            .ok_or_else(|| eyre!("client not found"))?;

        kubernetes::pod::delete(client, &pod).await?;

        Produces::ok(())
    }

    pub async fn delete_pods(
        &mut self,
        selected_cluster: ClusterId,
        pod_ids: Vec<PodId>,
    ) -> ActorResult<()> {
        if pod_ids.is_empty() {
            return Produces::ok(());
        }

        if pod_ids.len() == 1 {
            return self.delete_pod(selected_cluster, &pod_ids[0]).await;
        }

        debug!("deleting pods: {:?}", pod_ids);
        let LoadStatus::Loaded(pods) = &self.pods else {
            return Err(eyre::eyre!("pods not loaded").into());
        };

        let grouped: HashMap<String, Vec<PodId>> = pod_ids
            .into_iter()
            .filter_map(|pod_id| {
                let namespace = pods.get(&pod_id).as_ref()?.namespace.clone();
                Some((namespace, pod_id))
            })
            .fold(HashMap::new(), |mut acc, (namespace, pod_id)| {
                acc.entry(namespace).or_insert_with(Vec::new).push(pod_id);
                acc
            });

        let client = GlobalViewModel::global()
            .read()
            .get_cluster_client(&selected_cluster)
            .ok_or_else(|| eyre!("client not found"))?;

        let results: Vec<Result<Either<K8sPod, Status>, kubernetes::pod::Error>> = grouped
            .into_iter()
            .map(|(namespace, pod_ids)| {
                let client = client.clone();
                tokio::spawn(async move {
                    kubernetes::pod::delete_list_in_namespace(client, &namespace, pod_ids).await
                })
            })
            .collect::<FuturesUnordered<_>>()
            .collect::<Vec<_>>()
            .await
            .into_iter()
            .filter_map(Result::ok)
            .flatten()
            .collect();

        // send any errors as messages to the front end
        for result in results {
            if let Err(kubernetes::pod::Error::DeleteError(pod_id, error)) = result {
                error!("failed to delete pod ({pod_id}): {error:?}");
                self.callback(PodError::PodDeleteError(pod_id, error).into())
                    .await
            }
        }

        Produces::ok(())
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
        debug!("deleted: {:?}", pod.id);

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
        if let Some(pods) = self.pods_filtered_vec() {
            debug!("notifying pods loaded");

            self.callback(PodViewModelMessage::Loaded { pods }).await
        }
    }
}

impl From<PodError> for PodViewModelMessage {
    fn from(error: PodError) -> Self {
        use PodError as E;
        use PodViewModelMessage as Msg;

        match error {
            E::PodLoadError(e) => Msg::LoadingFailed {
                error: e.to_string(),
            },

            E::PodNotFoundForDelete(pod_id) => Msg::ToastWarningMessage {
                message: format!("Pod with id ({pod_id}) not found, unable to delete"),
            },

            E::PodDeleteError(pod_id, error) => Msg::ToastErrorMessage {
                message: format!("Unable to delete pod with id ({pod_id}), error: {error:?}"),
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
