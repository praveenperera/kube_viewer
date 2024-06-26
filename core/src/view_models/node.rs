use std::{collections::HashMap, sync::Arc};

use act_zero::*;
use eyre::{eyre, Result};
use kube::Client;
use log::{debug, error, warn};
use tokio::sync::RwLock;

use fake::{Fake, Faker};

use thiserror::Error;

use super::WindowId;
use crate::{
    cluster::ClusterId,
    kubernetes::{
        self,
        node::{Node, NodeId},
    },
    task,
};

use crate::view_models::global::GlobalViewModel;

#[derive(Error, Debug)]
pub enum NodeError {
    #[error(transparent)]
    NodeLoadError(eyre::Report),
}

#[uniffi::export(callback_interface)]
pub trait NodeViewModelCallback: Send + Sync + 'static {
    fn callback(&self, message: NodeViewModelMessage);
}

#[derive(uniffi::Enum)]
pub enum NodeViewModelMessage {
    Loading,
    Loaded { nodes: Vec<Node> },
    LoadingFailed { error: String },
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
            NodeError::NodeLoadError(e) => NodeViewModelMessage::LoadingFailed {
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

    nodes: Option<HashMap<NodeId, Node>>,
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

        Self { state, window_id }
    }

    pub fn preview(window_id: String) -> Self {
        let window_id = WindowId(window_id);

        let state = Arc::new(RwLock::new(State::preview()));
        Self { state, window_id }
    }
}

#[uniffi::export(async_runtime = "tokio")]
impl RustNodeViewModel {
    pub async fn add_callback_listener(&self, responder: Box<dyn NodeViewModelCallback>) {
        debug!("node view model callback listener added");

        let mut state = self.state.write().await;
        state.responder = Some(responder);
        state.extra_worker = Worker::start_actor(self.state.clone());
    }

    /// Sets the the loading status to loading and fetches the nodes for the selected cluster.
    pub async fn fetch_nodes(&self, selected_cluster: ClusterId) {
        debug!("fetching nodes");

        let worker = Worker::start_actor(self.state.clone());
        self.state.write().await.current_worker = worker.clone();

        let _ = call!(worker.notify_and_load_nodes(selected_cluster.clone())).await;
        let _ = call!(worker.start_watcher(selected_cluster.clone())).await;
    }

    pub async fn stop_watcher(&self) {
        debug!("stopping watcher");
        self.state.write().await.current_worker = Addr::default();
    }

    pub fn nodes(&self, selected_cluster: ClusterId) -> Vec<Node> {
        // TODO: handle error
        let state = self.state.clone();

        task::block_on(async move {
            state
                .read()
                .await
                .nodes(selected_cluster)
                .unwrap_or_default()
        })
    }
}

impl State {
    pub fn preview() -> Self {
        let mut nodes = HashMap::new();

        for _ in 0..16 {
            let node = Faker.fake::<Node>();
            nodes.insert(node.id.clone(), node);
        }

        Self {
            extra_worker: Default::default(),
            current_worker: Default::default(),
            nodes: Some(nodes),
            responder: None,
        }
    }

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
            send!(self.extra_worker.notify_and_load_nodes(selected_cluster));
        };

        let nodes = self
            .nodes
            .as_ref()
            .ok_or_else(|| eyre!("nodes not loaded"))?;

        Ok(nodes.values().cloned().collect())
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

    pub async fn callback(&self, msg: NodeViewModelMessage) {
        if let Some(responder) = self.state.read().await.responder.as_ref() {
            responder.callback(msg);
        } else {
            warn!("node view model callback called, before initialized");
        }
    }

    pub async fn applied(&mut self, node: Node) -> ActorResult<()> {
        if let Some(ref nodes) = self.state.read().await.nodes {
            if let Some(existing_node) = nodes.get(&node.id) {
                if existing_node == &node {
                    debug!("same node already exists, ignoring");
                    return Produces::ok(());
                }
            }
        };

        if let Some(ref mut nodes) = self.state.write().await.nodes {
            debug!("node updated, notifying listeners");
            nodes.insert(node.id.clone(), node);

            self.callback(NodeViewModelMessage::Loaded {
                nodes: nodes.values().cloned().collect(),
            })
            .await
        };

        Produces::ok(())
    }

    pub async fn deleted(&mut self, node: Node) -> ActorResult<()> {
        if let Some(nodes) = self.state.write().await.nodes.as_mut() {
            debug!("node deleted, notifying listeners");
            nodes.remove(&node.id);

            self.callback(NodeViewModelMessage::Loaded {
                nodes: nodes.values().cloned().collect(),
            })
            .await
        };

        Produces::ok(())
    }

    pub async fn load_nodes(&mut self, selected_cluster: impl AsRef<ClusterId>) -> ActorResult<()> {
        debug!("loading nodes");

        let selected_cluster = selected_cluster.as_ref();
        GlobalViewModel::check_and_load_client(selected_cluster).await?;

        let client: Client = GlobalViewModel::global()
            .read()
            .get_cluster_client(selected_cluster)
            .ok_or_else(|| eyre!("client not found"))?;

        let nodes = kubernetes::node::get_all(client.clone())
            .await
            .map_err(NodeError::NodeLoadError)?;

        self.state.write().await.nodes = Some(nodes.clone());

        // notify frontend, nodes loaded
        self.callback(NodeViewModelMessage::Loaded {
            nodes: nodes.into_values().collect(),
        })
        .await;

        Produces::ok(())
    }

    async fn notify_and_load_nodes(&mut self, selected_cluster: ClusterId) -> ActorResult<()> {
        // notify and load
        self.callback(NodeViewModelMessage::Loading).await;

        self.load_nodes(&selected_cluster)
            .await
            .map_err(|e| NodeError::NodeLoadError(eyre!("{e:?}")))?;

        Produces::ok(())
    }

    async fn start_watcher(&mut self, selected_cluster: ClusterId) -> ActorResult<()> {
        debug!("starting nodes watcher");

        let client: Client = GlobalViewModel::global()
            .read()
            .get_cluster_client(selected_cluster.as_ref())
            .ok_or_else(|| eyre!("client not found"))?;

        // start watcher
        self.addr.send_fut_with(|addr| async move {
            kubernetes::node::watch(addr, selected_cluster, client)
                .await
                .unwrap();
        });

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
            self.callback(error.into()).await
        } else {
            self.callback(NodeViewModelMessage::LoadingFailed {
                error: "Unknown error, please see logs".to_string(),
            })
            .await
        };

        false
    }
}
