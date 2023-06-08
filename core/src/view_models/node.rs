use std::sync::Arc;

use act_zero::*;
use eyre::{eyre, Result};
use kube::Client;
use log::{debug, error, warn};
use parking_lot::RwLock;

use thiserror::Error;

use super::WindowId;
use crate::{
    cluster::ClusterId,
    kubernetes::{self, node::Node},
    task,
};

use crate::view_models::global::GlobalViewModel;

#[derive(Error, Debug)]
pub enum NodeError {
    #[error(transparent)]
    NodeLoadError(eyre::Report),
}

pub trait NodeViewModelCallback: Send + Sync + 'static {
    fn callback(&self, message: NodeViewModelMessage);
}

pub enum NodeViewModelMessage {
    LoadingNodes,
    NodesLoaded,
    NodeLoadingFailed { error: String },
}

#[derive(uniffi::Enum)]
pub enum NodeLoadStatus {
    Initial,
    Loading,
    Loaded { nodes: Vec<Node> },
    Error { error: String },
}

impl From<NodeError> for NodeViewModelMessage {
    fn from(error: NodeError) -> Self {
        match error {
            NodeError::NodeLoadError(e) => NodeViewModelMessage::NodeLoadingFailed {
                error: e.to_string(),
            },
        }
    }
}

pub struct RustNodeViewModel {
    state: Arc<RwLock<State>>,

    #[allow(dead_code)]
    window_id: WindowId,
}

pub struct State {
    extra_worker: Addr<Worker>,
    current_worker: Addr<Worker>,

    nodes: Option<Vec<Node>>,
    responder: Option<Box<dyn NodeViewModelCallback>>,
}

pub struct Worker {
    addr: WeakAddr<Self>,
    state: Arc<RwLock<State>>,
}

impl RustNodeViewModel {
    pub fn new(window_id: String) -> Self {
        let window_id = WindowId(window_id);

        let state = Arc::new(RwLock::new(State::new(window_id.clone())));
        state.write().extra_worker = Worker::start_actor(state.clone());

        Self { state, window_id }
    }

    pub fn add_callback_listener(&self, responder: Box<dyn NodeViewModelCallback>) {
        self.state.write().responder = Some(responder);
    }
}

#[uniffi::export]
impl RustNodeViewModel {
    pub fn fetch_nodes(&self, selected_cluster: ClusterId) {
        let worker = Worker::start_actor(self.state.clone());
        self.state.write().current_worker = worker.clone();

        task::spawn(async move { send!(worker.fetch_nodes(selected_cluster)) });
    }

    pub fn nodes(&self, selected_cluster: ClusterId) -> Vec<Node> {
        // TODO: handle error
        self.state
            .read()
            .nodes(selected_cluster)
            .unwrap_or_default()
    }
}

impl State {
    pub fn new(_window_id: WindowId) -> Self {
        Self {
            extra_worker: Default::default(),
            current_worker: Default::default(),
            nodes: None,
            responder: None,
        }
    }

    pub fn nodes(&self, selected_cluster: ClusterId) -> Result<Vec<Node>> {
        debug!("getting nodes called");

        if self.nodes.is_none() {
            warn!("nodes not loaded, fetching nodes");
            send!(self.extra_worker.fetch_nodes(selected_cluster));
        };

        let nodes = self
            .nodes
            .as_ref()
            .ok_or_else(|| eyre!("nodes not loaded"))?;

        Ok(nodes.clone())
    }
}

impl Worker {
    pub fn start_actor(state: Arc<RwLock<State>>) -> Addr<Self> {
        task::spawn_actor(Self::new(state))
    }

    pub fn new(state: Arc<RwLock<State>>) -> Self {
        Self {
            addr: Default::default(),
            state,
        }
    }

    pub fn callback(&self, msg: NodeViewModelMessage) {
        if let Some(responder) = self.state.read().responder.as_ref() {
            responder.callback(msg);
        }
    }

    async fn fetch_nodes(&mut self, selected_cluster: ClusterId) -> ActorResult<()> {
        debug!("fetch_nodes() called");

        // notify and load
        self.callback(NodeViewModelMessage::LoadingNodes);

        self.load_nodes(&selected_cluster)
            .await
            .map_err(|e| NodeError::NodeLoadError(eyre!("{e:?}")))?;

        self.callback(NodeViewModelMessage::NodesLoaded);

        Produces::ok(())
    }

    async fn load_nodes(&mut self, selected_cluster: &ClusterId) -> ActorResult<()> {
        debug!("loading nodes");

        // notify frontend, nodes loaded
        self.callback(NodeViewModelMessage::LoadingNodes);

        if !GlobalViewModel::global()
            .read()
            .client_store
            .contains_client(selected_cluster)
        {
            self.load_client(selected_cluster).await?;
        };

        let client: Client = GlobalViewModel::global()
            .read()
            .get_cluster_client(selected_cluster)
            .ok_or_else(|| eyre!("client not found"))?;

        let nodes = kubernetes::get_nodes(client.clone())
            .await
            .map_err(NodeError::NodeLoadError)?;

        self.state.write().nodes = Some(nodes);

        self.addr.send_fut(async move {
            kubernetes::watch_nodes(client).await.unwrap();
        });

        // notify frontend, nodes loaded
        self.callback(NodeViewModelMessage::NodesLoaded);

        Produces::ok(())
    }

    async fn load_client(&mut self, selected_cluster: &ClusterId) -> ActorResult<()> {
        debug!("load_client() called");

        if !GlobalViewModel::global()
            .read()
            .client_store
            .contains_client(selected_cluster)
        {
            let client_worker = GlobalViewModel::global().read().worker.clone();
            call!(client_worker.load_client(selected_cluster.clone())).await?;
        }

        Produces::ok(())
    }
}

#[async_trait::async_trait]
impl Actor for Worker {
    async fn started(&mut self, addr: Addr<Self>) -> ActorResult<()> {
        self.addr = addr.downgrade();

        Produces::ok(())
    }

    async fn error(&mut self, error: ActorError) -> bool {
        error!("NodeViewModel Actor Error: {error:?}");

        if let Some(error) = error.downcast::<NodeError>().ok().map(|e| *e) {
            self.callback(error.into())
        } else {
            self.callback(NodeViewModelMessage::NodeLoadingFailed {
                error: "Unknown error, please see logs".to_string(),
            });
        };

        false
    }
}
