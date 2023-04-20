pub mod node;

use eyre::Result;
use k8s_openapi::api::core::v1::Node as K8sNode;
use kube::{Api, Client};

use self::node::Node;

pub async fn get_nodes(client: Client) -> Result<Vec<Node>> {
    let nodes_api: Api<K8sNode> = Api::all(client);
    let nodes = nodes_api.list(&Default::default()).await?;

    Ok(nodes.into_iter().map(Into::into).collect())
}
