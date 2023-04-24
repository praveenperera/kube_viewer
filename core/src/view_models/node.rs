use act_zero::*;
use kube::{config::KubeConfigOptions, Client, Config};

use super::WindowId;
use crate::{
    kubernetes::{self, node::Node},
    task,
    user_config::USER_CONFIG,
};

pub trait NodeViewModelCallback: Send {
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
    pub fn nodes(&self) -> Vec<Node> {
        let addr = self.inner.clone();
        task::block_on(async move { call!(addr.nodes()).await.unwrap_or_default() })
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
    client: Option<Client>,
    #[allow(dead_code)]
    window_id: WindowId,
    responder: Option<Box<dyn NodeViewModelCallback>>,
}

impl NodeViewModel {
    pub fn new(window_id: WindowId) -> Self {
        Self {
            addr: Default::default(),
            nodes: None,
            client: None,
            window_id,
            responder: None,
        }
    }

    async fn nodes(&mut self) -> ActorResult<Vec<Node>> {
        if self.nodes.is_none() {
            self.load_nodes().await?;
        }

        Produces::ok(self.nodes.clone().expect("just loaded nodes"))
    }

    async fn load_nodes(&mut self) -> ActorResult<()> {
        let client = self
            .client
            .as_ref()
            .ok_or_else(|| eyre::eyre!("Kubernetes client not loaded"))?
            .clone();

        let nodes = kubernetes::get_nodes(client).await?;
        self.nodes = Some(nodes);

        Produces::ok(())
    }

    async fn add_callback_listener(
        &mut self,
        responder: Box<dyn NodeViewModelCallback>,
    ) -> ActorResult<()> {
        self.responder = Some(responder);

        // after the responder is set, we can load the kubernetes client
        self.load_client().await?;

        Produces::ok(())
    }

    async fn load_client(&mut self) -> ActorResult<()> {
        let selected_cluster = USER_CONFIG.read().get_selected_cluster(&self.window_id);

        let config = match selected_cluster {
            None => Config::infer().await?,
            Some(selected_cluster) => {
                Config::from_kubeconfig(&KubeConfigOptions {
                    context: Some(selected_cluster.raw_value.clone()),
                    ..Default::default()
                })
                .await?
            }
        };

        let client = Client::try_from(config)?;
        self.client = Some(client);

        self.responder
            .as_ref()
            .unwrap()
            .callback(NodeViewModelMessage::ClientLoaded);

        self.load_nodes().await?;
        self.responder
            .as_ref()
            .unwrap()
            .callback(NodeViewModelMessage::NodesLoaded);

        Produces::ok(())
    }
}
