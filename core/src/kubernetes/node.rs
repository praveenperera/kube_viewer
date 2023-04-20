use chrono::{DateTime, Utc};
use k8s_openapi::api::core::v1::{
    Node as K8sNode, NodeAddress as K8sNodeAddress, Taint as K8sTaint,
};
use std::collections::BTreeMap;

pub struct Condition {
    pub name: String,
    pub status: String,
    pub reason: String,
    pub message: String,
}

pub struct Node {
    pub name: String,
    pub labels: BTreeMap<String, String>,
    pub annotations: BTreeMap<String, String>,
    pub taints: Vec<Taint>,
    pub addressees: Vec<NodeAddress>,
    pub os: Option<String>,
    pub arch: Option<String>,
    pub os_image: Option<String>,
    pub kernel_version: Option<String>,
    pub container_runtime: Option<String>,
    pub kubelet_version: Option<String>,
    pub condition: Condition,
}

pub struct Taint {
    pub effect: String,
    pub key: String,
    pub time_added: Option<DateTime<Utc>>,
    pub value: Option<String>,
}

pub struct NodeAddress {
    pub address: String,
    pub node_type: String,
}

impl From<K8sNodeAddress> for NodeAddress {
    fn from(address: K8sNodeAddress) -> Self {
        Self {
            address: address.address,
            node_type: address.type_,
        }
    }
}

impl From<K8sTaint> for Taint {
    fn from(taint: K8sTaint) -> Self {
        Self {
            effect: taint.effect,
            key: taint.key,
            time_added: taint.time_added.map(|time| time.0),
            value: taint.value,
        }
    }
}

impl From<K8sNode> for Node {
    fn from(node: K8sNode) -> Self {
        let node_info = node.status.and_then(|status| status.node_info);

        Self {
            name: node
                .metadata
                .name
                .unwrap_or_else(|| "Unknown node name".to_string()),
            labels: node.metadata.labels.unwrap_or_default(),
            annotations: node.metadata.annotations.unwrap_or_default(),
            taints: node
                .spec
                .and_then(|spec| spec.taints)
                .map(|taints| taints.into_iter().map(Taint::from).collect())
                .unwrap_or_default(),
            addressees: node
                .status
                .and_then(|status| status.addresses)
                .map(|addresses| addresses.into_iter().map(NodeAddress::from).collect())
                .unwrap_or_default(),
            os: node_info.map(|info| info.operating_system),
            arch: node_info.map(|info| info.architecture),
            os_image: node_info.map(|info| info.os_image),
            kernel_version: node_info.map(|info| info.kernel_version),
            container_runtime: node_info.map(|info| info.container_runtime_version),
            kubelet_version: node_info.map(|info| info.kubelet_version),
            condition: todo!(),
        }
    }
}
