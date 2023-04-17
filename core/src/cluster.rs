use derive_more::From;
use eyre::Result;
use kube::config::NamedCluster;
use std::collections::HashMap;

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, From, Hash, uniffi::Record)]
pub struct ClusterId {
    raw_value: String,
}

#[derive(Debug, Clone, uniffi::Record)]
pub struct Cluster {
    pub id: ClusterId,

    // set by user
    pub nickname: Option<String>,
    pub server: Option<String>,
    pub proxy_url: Option<String>,
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
        })
    }
}

pub fn get_clusters_hashmap() -> Result<HashMap<ClusterId, Cluster>> {
    let kube_config = kube::config::Kubeconfig::read()?;

    let clusters: HashMap<ClusterId, Cluster> = kube_config
        .clusters
        .into_iter()
        .map(Cluster::try_from)
        .filter_map(Result::ok)
        .map(|cluster| (cluster.id.clone(), cluster))
        .collect();

    Ok(clusters)
}
