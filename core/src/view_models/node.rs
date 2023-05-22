use std::{collections::HashMap, sync::Arc};

use act_zero::*;
use eyre::{eyre, Result};
use kube::{config::KubeConfigOptions, Client, Config};
use log::{debug, error};
use parking_lot::RwLock;

use thiserror::Error;

use super::WindowId;
use crate::{
    cluster::ClusterId,
    kubernetes::{self, node::Node},
    task,
};

#[derive(Error, Debug)]
pub enum NodeError {
    #[error(transparent)]
    NodeLoadError(eyre::Report),

    #[error(transparent)]
    ClientLoadError(eyre::Report),
}

pub trait NodeViewModelCallback: Send + Sync + 'static {
    fn callback(&self, message: NodeViewModelMessage);
}

#[derive(uniffi::Enum)]
pub enum NodeLoadStatus {
    Initial,
    Loading,
    Loaded { nodes: Vec<Node> },
    Error { error: String },
}

#[derive(uniffi::Enum)]
pub enum ClientLoadStatus {
    Initial,
    Loading,
    Loaded,
    Error { error: String },
}

pub enum NodeViewModelMessage {
    LoadingClient,
    LoadingNodes,
    ClientLoaded,
    NodesLoaded,
    NodeLoadingFailed { error: String },
    ClientLoadingFailed { error: String },
}

impl From<NodeError> for NodeViewModelMessage {
    fn from(error: NodeError) -> Self {
        match error {
            NodeError::NodeLoadError(e) => NodeViewModelMessage::NodeLoadingFailed {
                error: e.to_string(),
            },
            NodeError::ClientLoadError(e) => NodeViewModelMessage::ClientLoadingFailed {
                error: e.to_string(),
            },
        }
    }
}

pub struct RustNodeViewModel {
    actor: Addr<Worker>,
    state: Arc<RwLock<State>>,

    #[allow(dead_code)]
    window_id: WindowId,
}

pub struct State {
    actor: WeakAddr<Worker>,
    nodes: Option<Vec<Node>>,
    clients: HashMap<ClusterId, Client>,
}

pub struct Worker {
    addr: WeakAddr<Self>,

    state: Arc<RwLock<State>>,
    responder: Option<Box<dyn NodeViewModelCallback>>,
}

impl RustNodeViewModel {
    pub fn new(window_id: String) -> Self {
        let window_id = WindowId(window_id);

        let state = Arc::new(RwLock::new(State::new(window_id.clone())));
        let worker = Worker::new(window_id.clone(), state.clone());
        let actor = task::spawn_actor(worker);

        Self {
            actor,
            state,
            window_id,
        }
    }

    pub fn add_callback_listener(&self, responder: Box<dyn NodeViewModelCallback>) {
        let addr = self.actor.clone();
        task::spawn(async move { send!(addr.add_callback_listener(responder)) });
    }
}

#[uniffi::export]
impl RustNodeViewModel {
    pub fn fetch_nodes(&self, selected_cluster: ClusterId) {
        let addr = self.actor.clone();
        task::spawn(async move { send!(addr.fetch_nodes(selected_cluster)) });
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
            actor: WeakAddr::detached(),
            nodes: None,
            clients: HashMap::new(),
        }
    }

    pub fn nodes(&self, selected_cluster: ClusterId) -> Result<Vec<Node>> {
        debug!("getting nodes called");

        if self.nodes.is_none() {
            log::warn!("nodes not loaded, fetching nodes");
            send!(self.actor.fetch_nodes(selected_cluster));
        };

        let nodes = self
            .nodes
            .as_ref()
            .ok_or_else(|| eyre!("nodes not loaded"))?;

        Ok(nodes.clone())
    }
}

impl Worker {
    pub fn new(_window_id: WindowId, state: Arc<RwLock<State>>) -> Self {
        Self {
            addr: Default::default(),
            state,
            responder: None,
        }
    }

    pub fn callback(&self, msg: NodeViewModelMessage) {
        if let Some(responder) = self.responder.as_ref() {
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

        if !self.state.read().clients.contains_key(selected_cluster) {
            self.load_client(selected_cluster.clone())
                .await
                .map_err(|e| NodeError::ClientLoadError(eyre!("{e:?}")))?;
        }

        let client: Client = self
            .state
            .read()
            .clients
            .get(selected_cluster)
            .ok_or_else(|| NodeError::ClientLoadError(eyre!("Kubernetes client not loaded")))?
            .clone();

        let nodes = kubernetes::get_nodes(client.clone())
            .await
            .map_err(NodeError::NodeLoadError)?;

        self.state.write().nodes = Some(nodes);

        // notify frontend, nodes loaded
        self.callback(NodeViewModelMessage::NodesLoaded);

        Produces::ok(())
    }

    async fn add_callback_listener(
        &mut self,
        responder: Box<dyn NodeViewModelCallback>,
    ) -> ActorResult<()> {
        self.responder = Some(responder);

        Produces::ok(())
    }

    async fn load_client(&mut self, selected_cluster: ClusterId) -> ActorResult<()> {
        debug!("load_client() called");

        if self.state.read().clients.contains_key(&selected_cluster) {
            return Produces::ok(());
        }

        // notify frontend that client is loading
        self.callback(NodeViewModelMessage::LoadingClient);

        let config = Config::from_kubeconfig(&KubeConfigOptions {
            context: Some(selected_cluster.raw_value.clone()),
            ..Default::default()
        })
        .await
        .map_err(|e| NodeError::ClientLoadError(eyre!("{e:?}")))?;

        let client = Client::try_from(config)?;

        // save client to hashmap
        self.state
            .write()
            .clients
            .insert(selected_cluster.clone(), client);

        // notify frontend client is loaded
        self.callback(NodeViewModelMessage::ClientLoaded);

        Produces::ok(())
    }
}

#[async_trait::async_trait]
impl Actor for Worker {
    async fn started(&mut self, addr: Addr<Self>) -> ActorResult<()> {
        self.addr = addr.downgrade();
        self.state.write().actor = self.addr.clone();

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
