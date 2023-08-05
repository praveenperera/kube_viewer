use fake::Dummy;
use k8s_openapi::{
    api::core::v1::Toleration as K8sToleration,
    apimachinery::pkg::apis::meta::v1::OwnerReference as K8sOwnerReference,
};
use uniffi::Record;

#[derive(Debug, Clone, Default, PartialEq, Eq, Record, Dummy)]
pub struct OwnerReference {
    pub api_version: String,
    pub block_owner_deletion: bool,
    pub controller: bool,
    pub kind: String,
    pub name: String,
    pub uid: String,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Record, Dummy)]
pub struct Toleration {
    pub effect: Option<String>,
    pub key: Option<String>,
    pub operator: Option<String>,
    pub toleration_seconds: Option<i64>,
    pub value: Option<String>,
}

impl From<K8sOwnerReference> for OwnerReference {
    fn from(owner_reference: K8sOwnerReference) -> Self {
        Self {
            api_version: owner_reference.api_version,
            block_owner_deletion: owner_reference.block_owner_deletion.unwrap_or_default(),
            controller: owner_reference.controller.unwrap_or_default(),
            kind: owner_reference.kind,
            name: owner_reference.name,
            uid: owner_reference.uid,
        }
    }
}

impl From<K8sToleration> for Toleration {
    fn from(toleration: K8sToleration) -> Self {
        Self {
            effect: toleration.effect,
            key: toleration.key,
            operator: toleration.operator,
            toleration_seconds: toleration.toleration_seconds,
            value: toleration.value,
        }
    }
}
