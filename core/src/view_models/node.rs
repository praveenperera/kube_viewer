use act_zero::*;
use kube::{config::KubeConfigOptions, Client, Config};

use super::WindowId;
use crate::{env::Env, task, user_config::USER_CONFIG};

pub trait NodeViewModelCallback: Send {
    fn callback(&self, message: NodeViewModelMessage);
}

pub enum NodeViewModelMessage {
    ClientLoaded,
    PathFound { path: String },
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
impl RustNodeViewModel {}

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
    client: Option<Client>,
    #[allow(dead_code)]
    window_id: WindowId,
    responder: Option<Box<dyn NodeViewModelCallback>>,
}

impl NodeViewModel {
    pub fn new(window_id: WindowId) -> Self {
        Self {
            addr: Default::default(),
            client: None,
            window_id,
            responder: None,
        }
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
        self.responder
            .as_ref()
            .unwrap()
            .callback(NodeViewModelMessage::PathFound {
                path: std::env::var("PATH").unwrap_or_default(),
            });

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

        Produces::ok(())
    }
}
