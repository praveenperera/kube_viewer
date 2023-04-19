use parking_lot::RwLock;

use crate::{
    cluster::{Cluster, ClusterId, Clusters},
    user_config::UserConfig,
};
use std::collections::HashMap;

pub struct RustGlobalViewModel {
    inner: RwLock<GlobalViewModel>,
}

pub struct GlobalViewModel {
    user_config: UserConfig,
    clusters: Option<Clusters>,
}

impl RustGlobalViewModel {
    pub fn new() -> Self {
        Self {
            inner: RwLock::new(GlobalViewModel::new()),
        }
    }
}

#[uniffi::export]
impl RustGlobalViewModel {
    pub fn clusters(&self) -> HashMap<ClusterId, Cluster> {
        self.inner.read().clusters()
    }

    pub fn selected_cluster(&self) -> Option<ClusterId> {
        self.inner.read().user_config.selected_cluster.clone()
    }

    pub fn set_selected_cluster(&self, cluster_id: ClusterId) {
        self.inner
            .write()
            .user_config
            .set_selected_cluster(cluster_id);
    }
}

impl GlobalViewModel {
    pub fn new() -> Self {
        let mut user_config = UserConfig::load();
        let clusters = Clusters::try_new().ok();

        // set selected cluster to current context
        if user_config.selected_cluster.is_none() {
            if let Some(clusters) = &clusters {
                if let Some(cluster_id) = clusters.selected_cluster(&user_config) {
                    user_config.set_selected_cluster(cluster_id);
                }
            }
        }

        Self {
            user_config,
            clusters,
        }
    }

    pub fn clusters(&self) -> HashMap<ClusterId, Cluster> {
        self.clusters
            .as_ref()
            .map(|clusters| clusters.clusters_map.clone())
            .unwrap_or_default()
    }
}
