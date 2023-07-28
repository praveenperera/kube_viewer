use derive_more::From;
use fake::{Dummy, Fake, Faker};
use k8s_openapi::api::core::v1::{
    Node as K8sNode, NodeAddress as K8sNodeAddress, NodeCondition as K8sNodeCondition,
    NodeSystemInfo, Taint as K8sTaint,
};

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use uniffi::Record;
#[derive(
    Debug,
    Clone,
    Default,
    PartialEq,
    Eq,
    PartialOrd,
    Ord,
    From,
    Hash,
    Record,
    Serialize,
    Deserialize,
    Dummy,
)]
pub struct NodeId {
    pub raw_value: String,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Record, Dummy)]
pub struct NodeCondition {
    pub name: String,
    pub status: String,
    pub reason: Option<String>,
    pub message: Option<String>,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Record, Dummy)]
pub struct Node {
    pub id: NodeId,
    pub name: String,
    pub created_at: Option<i64>,
    pub labels: HashMap<String, String>,
    pub annotations: HashMap<String, String>,
    pub taints: Vec<Taint>,
    pub addresses: Vec<NodeAddress>,
    pub os: Option<String>,
    pub arch: Option<String>,
    pub os_image: Option<String>,
    pub kernel_version: Option<String>,
    pub container_runtime: Option<String>,
    pub kubelet_version: Option<String>,
    pub conditions: Vec<NodeCondition>,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Record, Dummy)]
pub struct Taint {
    pub effect: String,
    pub key: String,
    pub time_added: Option<String>,
    pub value: Option<String>,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Record, Dummy)]
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
            time_added: taint.time_added.map(|time| time.0.to_rfc2822()),
            value: taint.value,
        }
    }
}

impl From<K8sNodeCondition> for NodeCondition {
    fn from(condition: K8sNodeCondition) -> Self {
        Self {
            name: condition.type_,
            status: condition.status,
            reason: condition.reason,
            message: condition.message,
        }
    }
}

impl From<K8sNode> for Node {
    fn from(node: K8sNode) -> Self {
        let addresses = node
            .status
            .as_ref()
            .and_then(|status| status.addresses.clone())
            .map(|addresses| addresses.into_iter().map(NodeAddress::from).collect())
            .unwrap_or_default();

        let conditions = node
            .status
            .as_ref()
            .and_then(|status| {
                status.conditions.as_ref().map(|conditions| {
                    conditions
                        .iter()
                        .cloned()
                        .map(NodeCondition::from)
                        .collect::<Vec<NodeCondition>>()
                })
            })
            .unwrap_or_default();

        let node_info: Option<NodeSystemInfo> =
            node.status.and_then(|status| status.node_info).take();

        let (os, arch, os_image, kernel_version, container_runtime, kubelet_version) = node_info
            .map(|info| {
                (
                    Some(info.operating_system),
                    Some(info.architecture),
                    Some(info.os_image),
                    Some(info.kernel_version),
                    Some(info.container_runtime_version),
                    Some(info.kubelet_version),
                )
            })
            .unwrap_or((None, None, None, None, None, None));

        let node_name = node
            .metadata
            .name
            .unwrap_or_else(|| "Unknown node name".to_string());

        Self {
            id: node_name.clone().into(),
            name: node_name,
            created_at: node
                .metadata
                .creation_timestamp
                .map(|time| time.0.timestamp()),
            labels: node
                .metadata
                .labels
                .unwrap_or_default()
                .into_iter()
                .collect(),
            annotations: node
                .metadata
                .annotations
                .unwrap_or_default()
                .into_iter()
                .collect(),
            taints: node
                .spec
                .and_then(|spec| spec.taints)
                .map(|taints| taints.into_iter().map(Taint::from).collect())
                .unwrap_or_default(),
            addresses,
            os,
            arch,
            os_image,
            kernel_version,
            container_runtime,
            kubelet_version,
            conditions,
        }
    }
}

impl Node {
    pub fn preview() -> Self {
        Faker.fake()
    }
}

#[uniffi::export]
pub fn node_preview() -> Node {
    Node::preview()
}
