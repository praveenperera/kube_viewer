use std::collections::HashMap;

use kube::config::NamedCluster;

pub type ClusterId = String;

#[derive(Debug, Clone, uniffi::Record)]
pub struct Cluster {
    pub name: ClusterId,

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
            name: named_cluster.name,
            server: cluster.server,
            proxy_url: cluster.proxy_url,
        })
    }
}

pub fn get_clusters_hashmap() -> eyre::Result<HashMap<String, Cluster>> {
    let kube_config = kube::config::Kubeconfig::read()?;

    let clusters: HashMap<String, Cluster> = kube_config
        .clusters
        .into_iter()
        .map(Cluster::try_from)
        .filter_map(Result::ok)
        .map(|cluster| (cluster.name.clone(), cluster))
        .collect();

    Ok(clusters)
}
