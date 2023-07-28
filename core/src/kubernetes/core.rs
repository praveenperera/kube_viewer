use fake::Dummy;
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
