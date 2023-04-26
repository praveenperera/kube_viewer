use once_cell::sync::OnceCell;
use parking_lot::RwLock;

use crate::{
    cluster::{Cluster, ClusterId, Clusters},
    env::Env,
};
use std::collections::HashMap;

static INSTANCE: OnceCell<RwLock<GlobalViewModel>> = OnceCell::new();

impl GlobalViewModel {
    pub fn global() -> &'static RwLock<GlobalViewModel> {
        INSTANCE.get_or_init(|| RwLock::new(GlobalViewModel::new()))
    }
}

pub struct RustGlobalViewModel;

#[derive(Debug)]
pub struct GlobalViewModel {
    pub clusters: Option<Clusters>,
}

impl Default for RustGlobalViewModel {
    fn default() -> Self {
        Self::new()
    }
}

impl Default for GlobalViewModel {
    fn default() -> Self {
        Self::new()
    }
}

impl RustGlobalViewModel {
    pub fn new() -> Self {
        //TODO: set manually in code for now
        std::env::set_var("RUST_LOG", "debug");

        // one time init
        env_logger::init();

        Self
    }

    pub fn inner(&self) -> &RwLock<GlobalViewModel> {
        GlobalViewModel::global()
    }
}

#[uniffi::export]
impl RustGlobalViewModel {
    pub fn clusters(&self) -> HashMap<ClusterId, Cluster> {
        self.inner().read().clusters()
    }
}

impl GlobalViewModel {
    pub fn new() -> Self {
        // init env
        let _ = Env::global();

        let clusters = Clusters::try_new().ok();

        Self { clusters }
    }

    pub fn clusters(&self) -> HashMap<ClusterId, Cluster> {
        self.clusters
            .as_ref()
            .map(|clusters| clusters.clusters_map.clone())
            .unwrap_or_default()
    }

    pub fn get_cluster(&self, cluster_id: &ClusterId) -> Option<Cluster> {
        let clusters = self.clusters.as_ref()?;
        clusters.get_cluster(cluster_id)
    }
}
