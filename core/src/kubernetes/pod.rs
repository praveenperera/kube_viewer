use std::collections::HashMap;

use crate::UniffiCustomTypeConverter;
use derive_more::From;
use fake::{Dummy, Fake, Faker};
use k8s_openapi::api::core::v1::Pod as K8sPod;
use serde::{Deserialize, Serialize};
use uniffi::{Enum, Record};

use super::{core::OwnerReference, core::Toleration};

#[derive(uniffi::CustomType)]
#[uniffi(newtype=String)]
#[derive(
    Debug, Clone, Default, PartialEq, Eq, PartialOrd, Ord, From, Hash, Serialize, Deserialize, Dummy,
)]
pub struct PodId(String);

#[derive(Debug, Clone, Default, PartialEq, Eq, Record, Dummy)]
pub struct Pod {
    pub id: PodId,
    pub name: String,
    pub namespace: String,
    pub created_at: Option<i64>,
    pub labels: HashMap<String, String>,
    pub annotations: HashMap<String, String>,
    pub containers: Vec<Container>,
    pub pod_ip: Option<String>,
    pub host_ip: Option<String>,
    pub pod_ips: Vec<String>,
    pub qos_class: Option<String>,
    pub message: Option<String>,
    pub phase: Phase,
    // TODO: link to owner
    pub controlled_by: Option<OwnerReference>,

    // TODO: link to service account screen
    pub service_account: Option<String>,

    pub conditions: Vec<PodCondition>,
    pub tolerations: Vec<Toleration>,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Record, Dummy)]
pub struct Container {
    container_id: Option<String>,
    name: String,
    image: String,
    image_id: String,
    last_state: Option<ContainerState>,
    ready: bool,
    restart_count: i32,
    started: bool,
    state: Option<ContainerState>,
    ports: Vec<u32>,
}

#[derive(Debug, Clone, PartialEq, Eq, Enum, Dummy)]
pub enum ContainerState {
    Running { data: ContainerStateRunning },
    Terminated { data: ContainerStateTerminated },
    Waiting { data: ContainerStateWaiting },
}

impl Default for ContainerState {
    fn default() -> Self {
        Self::Waiting {
            data: ContainerStateWaiting::default(),
        }
    }
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Enum, Dummy)]
pub enum Phase {
    #[default]
    Pending,
    Running,
    Failed,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Record, Dummy)]
pub struct ContainerStateRunning {
    started_at: i64,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Record, Dummy)]
pub struct ContainerStateTerminated {
    started_at: i64,
    finished_at: i64,
    exit_code: i32,
    message: Option<String>,
    reason: Option<String>,
    signal: Option<i32>,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Record, Dummy)]
pub struct ContainerStateWaiting {
    message: Option<String>,
    reason: Option<String>,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Record, Dummy)]
pub struct PodCondition {
    pub last_probe_time: Option<i64>,
    pub last_transition_time: Option<i64>,
    pub message: Option<String>,
    pub reason: Option<String>,
    pub status: String,
    pub type_: String,
}

impl Pod {
    pub fn preview() -> Self {
        Faker.fake()
    }
}

#[uniffi::export]
pub fn pod_preview() -> Pod {
    Pod::preview()
}
