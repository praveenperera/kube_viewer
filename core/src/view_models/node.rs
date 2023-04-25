use std::collections::HashMap;

use act_zero::*;
use kube::{config::KubeConfigOptions, Client, Config};

use super::WindowId;
use crate::{
    cluster::ClusterId,
    kubernetes::{self, node::Node},
    task,
};

pub trait NodeViewModelCallback: Send + Sync + 'static {
    fn callback(&self, message: NodeViewModelMessage);
}

pub enum NodeViewModelMessage {
    ClientLoaded,
    NodesLoaded,
}

pub struct RustNodeViewModel {
    inner: Addr<NodeViewModel>,
    #[allow(dead_code)]
    window_id: WindowId,
}

impl RustNodeViewModel {
    pub fn new(window_id: String) -> Self {
        let window_id = WindowId(window_id);

        let model = NodeViewModel::new(window_id.clone());
        let inner = task::spawn_actor(model);

        Self { inner, window_id }
    }

    pub fn add_callback_listener(&self, responder: Box<dyn NodeViewModelCallback>) {
        let addr = self.inner.clone();
        task::spawn(async move { send!(addr.add_callback_listener(responder)) });
    }
}

#[uniffi::export]
impl RustNodeViewModel {
    pub fn fetch_nodes(&self, selected_cluster: ClusterId) {
        let addr = self.inner.clone();
        task::spawn(async move { send!(addr.fetch_nodes(selected_cluster)) });
    }

    pub fn nodes(&self, selected_cluster: ClusterId) -> Vec<Node> {
        let addr = self.inner.clone();
        task::block_on(async move {
            call!(addr.nodes(selected_cluster))
                .await
                .unwrap_or_default()
        })
    }
}

#[async_trait::async_trait]
impl Actor for NodeViewModel {
    async fn started(&mut self, addr: Addr<Self>) -> ActorResult<()> {
        self.addr = addr.downgrade();
        Produces::ok(())
    }

    async fn error(&mut self, error: ActorError) -> bool {
        log::error!("NodeViewModel Actor Error: {error:?}");
        false
    }
}

pub struct NodeViewModel {
    addr: WeakAddr<Self>,
    nodes: Option<Vec<Node>>,
    clients: HashMap<ClusterId, Client>,
    #[allow(dead_code)]
    window_id: WindowId,
    responder: Option<Box<dyn NodeViewModelCallback>>,
}

impl NodeViewModel {
    pub fn new(window_id: WindowId) -> Self {
        Self {
            addr: Default::default(),
            nodes: None,
            clients: HashMap::new(),
            window_id,
            responder: None,
        }
    }

    pub fn callback(&self, msg: NodeViewModelMessage) {
        if let Some(responder) = self.responder.as_ref() {
            responder.callback(msg);
        }
    }

    async fn fetch_nodes(&mut self, selected_cluster: ClusterId) -> ActorResult<()> {
        log::debug!("fetch_nodes() called");
        println!("fetch_nodes() called");
        self.load_nodes(&selected_cluster).await?;
        self.callback(NodeViewModelMessage::NodesLoaded);

        Produces::ok(())
    }

    async fn nodes(&mut self, selected_cluster: ClusterId) -> ActorResult<Vec<Node>> {
        println!("nodes() called");

        if self.nodes.is_none() {
            println!("nodes() called, but nodes is None, loading nodes");
            self.fetch_nodes(selected_cluster).await?;
        }

        Produces::ok(self.nodes.clone().expect("just loaded nodes"))
    }

    async fn load_nodes(&mut self, selected_cluster: &ClusterId) -> ActorResult<()> {
        if !self.clients.contains_key(selected_cluster) {
            self.load_client(selected_cluster.clone()).await?;
        }

        let client: Client = self
            .clients
            .get(selected_cluster)
            .ok_or_else(|| eyre::eyre!("Kubernetes client not loaded"))?
            .clone();

        let nodes = kubernetes::get_nodes(client.clone()).await?;
        self.nodes = Some(nodes);

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
        if self.clients.contains_key(&selected_cluster) {
            return Produces::ok(());
        }

        let config = Config::from_kubeconfig(&KubeConfigOptions {
            context: Some(selected_cluster.raw_value.clone()),
            ..Default::default()
        })
        .await?;

        let client = Client::try_from(config)?;

        // save client to hashmap
        self.clients.insert(selected_cluster.clone(), client);

        // notify frontend
        self.callback(NodeViewModelMessage::ClientLoaded);

        Produces::ok(())
    }
}
