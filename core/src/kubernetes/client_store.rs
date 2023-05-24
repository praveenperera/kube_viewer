use crate::cluster::ClusterId;
use crate::task;
use act_zero::*;
use kube::Client;
use parking_lot::RwLock;
use std::collections::HashMap;
use std::sync::Arc;

#[derive(uniffi::Enum)]
pub enum ClientLoadStatus {
    Initial,
    Loading,
    Loaded,
    Error { error: String },
}

#[derive(Clone)]
pub struct ClientStore {
    worker: Addr<Worker>,
    state: Arc<RwLock<HashMap<ClusterId, Client>>>,
}

impl ClientStore {
    pub fn new() -> Self {
        let state = Arc::new(RwLock::new(HashMap::new()));
        let worker = task::spawn_actor(Worker::new(state.clone()));

        Self { worker, state }
    }

    pub fn get_cluster_client(&self, cluster_id: &ClusterId) -> Option<Client> {
        self.state.read().get(cluster_id).cloned()
    }
}

#[derive(Clone)]
struct Worker {
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
