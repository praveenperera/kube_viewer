use crate::cluster::ClusterId;
use act_zero::WeakAddr;
use act_zero::*;
use kube::Client;
use std::collections::HashMap;

#[derive(uniffi::Enum)]
pub enum ClientLoadStatus {
    Initial,
    Loading,
    Loaded,
    Error { error: String },
}

pub struct ClientStore {
    addr: WeakAddr<Self>,
    data: HashMap<ClusterId, Client>,
    responder: 
}

#[async_trait::async_trait]
impl Actor for ClientStore {
    async fn started(&mut self, addr: Addr<Self>) -> ActorResult<()> {
        self.addr = addr.downgrade();

        Produces::ok(())
    }

    async fn error(&mut self, error: ActorError) -> bool {
        log::error!("ClientActor Actor Error: {error:?}");

        false
    }
}
