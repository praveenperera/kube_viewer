use crate::cluster::ClusterId;
use crate::task;
use act_zero::*;
use kube::config::KubeConfigOptions;
use kube::{Client, Config};
use parking_lot::RwLock;
use std::collections::HashMap;
use std::sync::Arc;

#[derive(Clone)]
pub struct ClientStore {
    pub worker: Addr<Worker>,
    state: Arc<RwLock<HashMap<ClusterId, Client>>>,
}

impl Default for ClientStore {
    fn default() -> Self {
        Self::new()
    }
}

impl ClientStore {
    pub fn new() -> Self {
        Self {
            worker: Default::default(),
            state: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    pub async fn start_worker(&mut self) {
        let worker = task::spawn_actor(Worker::new(self.state.clone()));
        self.worker = worker;
    }

    pub async fn load_client(&mut self, cluster_id: ClusterId) -> ActorResult<()> {
        call!(self.worker.load_client(cluster_id)).await?;

        Produces::ok(())
    }

    pub fn contains_client(&self, cluster_id: &ClusterId) -> bool {
        self.state.read().contains_key(cluster_id)
    }

    pub fn get_cluster_client(&self, cluster_id: &ClusterId) -> Option<Client> {
        self.state.read().get(cluster_id).cloned()
    }
}

#[derive(Clone)]
pub struct Worker {
    addr: WeakAddr<Self>,
    state: Arc<RwLock<HashMap<ClusterId, Client>>>,
}

impl Worker {
    fn new(state: Arc<RwLock<HashMap<ClusterId, Client>>>) -> Self {
        Self {
            addr: WeakAddr::detached(),
            state,
        }
    }

    pub async fn load_client(&mut self, cluster_id: ClusterId) -> ActorResult<()> {
        let config = Config::from_kubeconfig(&KubeConfigOptions {
            context: Some(cluster_id.raw_value.clone()),
            ..Default::default()
        })
        .await?;

        let client = Client::try_from(config)?;
        self.state.write().insert(cluster_id, client);

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
        log::error!("ClientActor Actor Error: {error:?}");
        false
    }
}
