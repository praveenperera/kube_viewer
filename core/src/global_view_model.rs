use parking_lot::RwLock;

use crate::cluster::{Cluster, ClusterId};
use std::collections::HashMap;

pub struct RustGlobalViewModel {
    inner: RwLock<GlobalViewModel>,
}

pub struct GlobalViewModel {
    clusters: HashMap<ClusterId, Cluster>,
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
        self.inner.read().clusters.clone()
    }
}

impl GlobalViewModel {
    pub fn new() -> Self {
        Self {
            clusters: crate::cluster::get_clusters_hashmap().unwrap_or_default(),
        }
    }
}
