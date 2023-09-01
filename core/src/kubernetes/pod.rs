use std::collections::HashMap;

use crate::{cluster::ClusterId, view_models::pod::PodViewModel, UniffiCustomTypeConverter};
use act_zero::{call, Addr};
use derive_more::{AsRef, Display, From};
use either::Either;
use eyre::Result;
use fake::{Dummy, Fake, Faker};
use futures::{StreamExt, TryStreamExt};
use k8s_openapi::api::core::v1::Pod as K8sPod;
use kube::{api::DeleteParams, core::Status, Api, Client};
use log::debug;
use rand::{distributions::Alphanumeric, Rng};
use serde::{Deserialize, Serialize};
use uniffi::{Enum, Record};

use k8s_openapi::api::core::v1::{
    Container as K8sContainer, ContainerState as K8sContainerState,
    ContainerStatus as K8sContainerStatus, PodCondition as K8sPodCondition,
};

use super::{core::OwnerReference, core::Toleration};

#[derive(uniffi::CustomType)]
#[uniffi(newtype=String)]
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
    Serialize,
    Deserialize,
    Dummy,
    Display,
    AsRef,
)]
pub struct PodId(String);

#[derive(uniffi::CustomType)]
#[uniffi(newtype=String)]
#[derive(
    Debug, Clone, Default, PartialEq, Eq, PartialOrd, Ord, From, Hash, Serialize, Deserialize, Dummy,
)]
pub struct ContainerId(String);

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
    pub controlled_by: Vec<OwnerReference>,

    // TODO: link to service account screen
    pub service_account: Option<String>,

    pub conditions: Vec<PodCondition>,
    pub tolerations: Vec<Toleration>,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Record, Dummy)]
pub struct Container {
    id: ContainerId,
    name: String,
    image: String,
    image_id: Option<String>,
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
    Succeeded,
    Unknown {
        raw_value: String,
    },
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

impl From<K8sPod> for Pod {
    fn from(pod: K8sPod) -> Self {
        let containers = pod
            .spec
            .as_ref()
            .map(|s| s.containers.clone())
            .unwrap_or_default();

        let pod_status = pod.status.as_ref();

        let container_statuses = pod_status
            .and_then(|s| s.container_statuses.clone())
            .unwrap_or_default()
            .into_iter()
            .map(|status| (ContainerId::from(status.name.clone()), status))
            .collect::<HashMap<ContainerId, _>>();

        Self {
            id: pod
                .metadata
                .name
                .as_ref()
                .map(ToString::to_string)
                .unwrap_or_else(|| format! {"unknown-node-name-{}", random()})
                .into(),
            name: pod
                .metadata
                .name
                .unwrap_or_else(|| "Unknown node name".to_string()),
            namespace: pod
                .metadata
                .namespace
                .unwrap_or_else(|| "default".to_string()),
            created_at: pod.metadata.creation_timestamp.map(|t| t.0.timestamp()),
            labels: pod
                .metadata
                .labels
                .unwrap_or_default()
                .into_iter()
                .collect(),
            annotations: pod
                .metadata
                .annotations
                .unwrap_or_default()
                .into_iter()
                .collect(),
            containers: containers
                .into_iter()
                .map(|container| Container::new(container, &container_statuses))
                .collect(),
            pod_ip: pod_status.and_then(|s| s.pod_ip.clone()),
            host_ip: pod_status.and_then(|s| s.host_ip.clone()),
            pod_ips: pod_status
                .and_then(|s| s.pod_ips.clone())
                .unwrap_or_default()
                .into_iter()
                .flat_map(|ip| ip.ip)
                .collect(),
            qos_class: pod_status.and_then(|s| s.qos_class.clone()),
            message: pod_status.and_then(|s| s.message.clone()),
            phase: pod_status
                .map(|s| Phase::from(s.phase.clone()))
                .unwrap_or_default(),
            controlled_by: pod
                .metadata
                .owner_references
                .unwrap_or_default()
                .into_iter()
                .map(Into::into)
                .collect(),
            service_account: pod
                .spec
                .as_ref()
                .and_then(|s| s.service_account_name.clone())
                .or_else(|| pod.spec.as_ref()?.service_account.clone()),
            conditions: pod_status
                .and_then(|s| s.conditions.clone())
                .unwrap_or_default()
                .into_iter()
                .map(Into::into)
                .collect(),
            tolerations: pod
                .spec
                .as_ref()
                .and_then(|s| s.tolerations.clone())
                .unwrap_or_default()
                .into_iter()
                .map(Into::into)
                .collect(),
        }
    }
}

impl Container {
    fn new(container: K8sContainer, statuses: &HashMap<ContainerId, K8sContainerStatus>) -> Self {
        let container_id = ContainerId::from(container.name.clone());
        let status = statuses.get(&container_id);

        Self {
            id: container_id,
            name: container.name,
            image: container.image.unwrap_or_default(),
            image_id: status.map(|s| s.image_id.clone()),
            last_state: status.and_then(|s| s.last_state.clone()).map(Into::into),
            ready: status.map(|s| s.ready).unwrap_or_default(),
            restart_count: status.map(|s| s.restart_count).unwrap_or_default(),
            started: status.map(|s| s.started).is_some(),
            state: status.and_then(|s| s.state.clone()).map(Into::into),
            ports: container
                .ports
                .unwrap_or_default()
                .into_iter()
                .map(|port| port.container_port as u32)
                .collect(),
        }
    }
}

impl From<K8sContainerState> for ContainerState {
    fn from(state: K8sContainerState) -> Self {
        match state {
            K8sContainerState {
                running: Some(running),
                ..
            } => Self::Running {
                data: ContainerStateRunning {
                    started_at: running
                        .started_at
                        .map(|t| t.0.timestamp())
                        .unwrap_or_default(),
                },
            },

            K8sContainerState {
                terminated: Some(terminated),
                ..
            } => Self::Terminated {
                data: ContainerStateTerminated {
                    started_at: terminated
                        .started_at
                        .map(|t| t.0.timestamp())
                        .unwrap_or_default(),
                    finished_at: terminated
                        .finished_at
                        .map(|t| t.0.timestamp())
                        .unwrap_or_default(),
                    exit_code: terminated.exit_code,
                    message: terminated.message,
                    reason: terminated.reason,
                    signal: terminated.signal,
                },
            },

            K8sContainerState {
                waiting: Some(waiting),
                ..
            } => Self::Waiting {
                data: ContainerStateWaiting {
                    message: waiting.message,
                    reason: waiting.reason,
                },
            },

            _ => Self::Waiting {
                data: ContainerStateWaiting {
                    message: None,
                    reason: None,
                },
            },
        }
    }
}

impl From<Option<String>> for Phase {
    fn from(phase: Option<String>) -> Self {
        if phase.is_none() {
            return Self::Pending;
        }

        match phase.expect("just checked").to_lowercase().as_str() {
            "pending" => Self::Pending,
            "running" => Self::Running,
            "failed" => Self::Failed,
            "succeeded" => Self::Succeeded,
            unknown => Self::Unknown {
                raw_value: unknown.to_string(),
            },
        }
    }
}

impl From<K8sPodCondition> for PodCondition {
    fn from(pod_condition: K8sPodCondition) -> Self {
        Self {
            last_probe_time: pod_condition.last_probe_time.map(|t| t.0.timestamp()),
            last_transition_time: pod_condition.last_transition_time.map(|t| t.0.timestamp()),
            message: pod_condition.message,
            reason: pod_condition.reason,
            status: pod_condition.status,
            type_: pod_condition.type_,
        }
    }
}

fn random() -> String {
    rand::thread_rng()
        .sample_iter(&Alphanumeric)
        .take(7)
        .map(char::from)
        .collect()
}

impl Pod {
    pub fn preview() -> Self {
        Faker.fake()
    }

    pub fn total_restart_count(&self) -> i32 {
        self.containers.iter().map(|c| c.restart_count).sum()
    }
}

pub async fn get_all(client: Client) -> Result<HashMap<PodId, Pod>> {
    let pods_api: Api<K8sPod> = Api::all(client);
    let pods = pods_api.list(&Default::default()).await?;

    let pods_hash_map = pods
        .into_iter()
        .map(Into::<Pod>::into)
        .map(|pod| (pod.id.clone(), pod))
        .collect();

    Ok(pods_hash_map)
}

pub async fn delete(client: Client, pod: &Pod) -> Result<Either<K8sPod, Status>, kube::Error> {
    let pods_api: Api<K8sPod> = Api::namespaced(client, &pod.namespace);

    pods_api
        .delete(pod.id.as_ref(), &DeleteParams::default())
        .await
}

pub async fn watch(
    addr: Addr<PodViewModel>,
    selected_cluster: ClusterId,
    client: Client,
) -> Result<()> {
    use kube::runtime::watcher;
    debug!("starting pod watcher for {:?}", selected_cluster);

    let nodes_api: Api<K8sPod> = Api::all(client);

    let mut stream = watcher(nodes_api, watcher::Config::default()).boxed();

    while let Some(status) = stream.try_next().await? {
        match status {
            watcher::Event::Applied(pod) => {
                debug!("applied event received on cluster {:?}", selected_cluster);
                call!(addr.applied(pod.into())).await?;
            }
            watcher::Event::Deleted(pod) => {
                debug!("deleted event received on cluster {:?}", selected_cluster);
                call!(addr.deleted(pod.into())).await?;
            }
            watcher::Event::Restarted(_) => {
                debug!("restarted event received on cluster {:?}", selected_cluster);
                let _ = call!(addr.load_pods(selected_cluster.clone())).await;
            }
        }
    }

    Ok(())
}
