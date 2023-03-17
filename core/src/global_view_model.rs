use crate::cluster::Cluster;
use std::{collections::HashMap, sync::RwLock};

pub struct RustGlobalViewModel {
    inner: RwLock<GlobalViewModel>,
}

pub struct GlobalViewModel {
    clusters: HashMap<String, Cluster>,
}

impl RustGlobalViewModel {
    pub fn new() -> Self {
        Self {
            inner: RwLock::new(GlobalViewModel::new()),
        }
    }
}

impl GlobalViewModel {
    pub fn new() -> Self {
        Self {
            clusters: crate::cluster::get_clusters_hashmap().unwrap_or_default(),
        }
    }
}
