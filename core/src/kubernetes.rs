pub mod client_store;
pub mod kube_config;
pub mod node;

use std::collections::HashMap;

use act_zero::{send, WeakAddr};
use eyre::Result;
use futures::{StreamExt, TryStreamExt};
use k8s_openapi::api::core::v1::Node as K8sNode;
use log::debug;

use kube::{runtime::watcher, Api, Client};

use crate::{cluster::ClusterId, view_models::node::Worker as NodeWorker};

use self::node::{Node, NodeId};

pub async fn get_nodes(client: Client) -> Result<HashMap<NodeId, Node>> {
    let nodes_api: Api<K8sNode> = Api::all(client);
    let nodes = nodes_api.list(&Default::default()).await?;

    let nodes_hash_map = nodes
        .into_iter()
        .map(Into::<Node>::into)
        .map(|node| (node.id.clone(), node))
        .collect();

    Ok(nodes_hash_map)
}

pub async fn watch_nodes(
    addr: WeakAddr<NodeWorker>,
    selected_cluster: ClusterId,
    client: Client,
) -> Result<()> {
    debug!("watch_nodes called");

    let nodes_api: Api<K8sNode> = Api::all(client);

    let mut stream = watcher(nodes_api, watcher::Config::default()).boxed();

    while let Some(status) = stream.try_next().await? {
        match status {
            watcher::Event::Applied(node) => {
                debug!("applied event received on cluster {:?}", selected_cluster);
                send!(addr.applied(node.into()))
            }
            watcher::Event::Deleted(node) => {
                debug!("deleted event received on cluster {:?}", selected_cluster);
                send!(addr.deleted(node.into()))
            }
            watcher::Event::Restarted(_) => {
                debug!("restarted event received on cluster {:?}", selected_cluster);
                send!(addr.load_nodes(selected_cluster.clone()))
            }
        }
    }

    Ok(())
}
