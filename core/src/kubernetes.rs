pub mod client_store;
pub mod kube_config;
pub mod node;

use std::collections::HashMap;

use eyre::Result;
use futures::{StreamExt, TryStreamExt};
use k8s_openapi::api::core::v1::Node as K8sNode;
use log::debug;

use kube::{api::ResourceExt, runtime::watcher, Api, Client};

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

pub async fn watch_nodes(client: Client) -> Result<()> {
    debug!("watch_nodes called");

    let nodes_api: Api<K8sNode> = Api::all(client);

    let mut stream = watcher(nodes_api, watcher::Config::default()).boxed();

    while let Some(status) = stream.try_next().await? {
        match status {
            watcher::Event::Applied(res) => {
                debug!("Applied: {}", res.name_any());
            }
            watcher::Event::Deleted(res) => {
                debug!("Deleted: {}", res.name_any());
            }
            watcher::Event::Restarted(res) => {
                debug!(
                    "Restarted: {}",
                    res.iter()
                        .map(|n| n.name_any())
                        .collect::<Vec<String>>()
                        .join(", ")
                );
            }
        }
    }

    Ok(())
}
