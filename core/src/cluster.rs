use derive_more::From;
use eyre::Result;
use kube::config::NamedCluster;
use std::collections::HashMap;

use serde::{Deserialize, Serialize};

use crate::LoadStatus;

#[derive(Debug, Clone)]
pub struct Clusters {
    pub kube_config: kube::config::Kubeconfig,
    pub clusters_map: HashMap<ClusterId, Cluster>,
}

impl Clusters {
    pub fn try_new() -> Result<Self> {
        let kube_config = kube::config::Kubeconfig::read()?;

        let clusters_map: HashMap<ClusterId, Cluster> = kube_config
            .clusters
            .clone()
            .into_iter()
            .map(Cluster::try_from)
            .filter_map(Result::ok)
            .map(|cluster| (cluster.id.clone(), cluster))
            .collect();

        Ok(Self {
            kube_config,
            clusters_map,
        })
    }

    pub fn get_cluster(&self, cluster_id: &ClusterId) -> Option<Cluster> {
        self.clusters_map.get(cluster_id).cloned()
    }

    pub fn get_cluster_mut(&mut self, cluster_id: &ClusterId) -> Option<&mut Cluster> {
        self.clusters_map.get_mut(cluster_id)
    }

    pub fn selected_or_context_cluster(
        &self,
        selected_cluster: Option<ClusterId>,
    ) -> Option<ClusterId> {
        if selected_cluster.is_none() {
            // default to current_context
            return self.current_context_cluster_id();
        };

        self.clusters_map
            .get(&selected_cluster.unwrap())
            .map(|cluster| cluster.id.clone())
            // if user has selected a cluster, but it's not in the kubeconfig, use current_context
            .or_else(|| self.current_context_cluster_id())
    }

    pub fn current_context_cluster_id(&self) -> Option<ClusterId> {
        self.kube_config
            .current_context
            .as_ref()
            .and_then(|cluster_id| self.clusters_map.get(&cluster_id.clone().into()))
            .map(|cluster| cluster.id.clone())
    }
}

/// Clusters

#[derive(
    Debug, Clone, PartialEq, Eq, PartialOrd, Ord, From, Hash, uniffi::Record, Serialize, Deserialize,
)]
pub struct ClusterId {
    pub raw_value: String,
}

#[derive(Debug, Clone, uniffi::Record)]
pub struct Cluster {
    // set in kubeconfig
    pub id: ClusterId,
    pub server: Option<String>,
    pub proxy_url: Option<String>,

    // set by user
    pub nickname: Option<String>,

    // status
    pub load_status: LoadStatus,
}

impl TryFrom<NamedCluster> for Cluster {
    type Error = eyre::Report;

    fn try_from(named_cluster: NamedCluster) -> Result<Self, Self::Error> {
        let cluster = named_cluster
            .cluster
            .ok_or_else(|| eyre::eyre!("cluster not present in named cluster"))?;

        Ok(Self {
            nickname: None,
            id: named_cluster.name.into(),
            server: cluster.server,
            proxy_url: cluster.proxy_url,
            load_status: LoadStatus::Initial,
        })
    }
}
