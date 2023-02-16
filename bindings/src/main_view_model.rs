use std::{collections::HashMap, sync::RwLock};

use crate::{
    tab::{Tab, TabId},
    tab_group::{TabGroup, TabGroupId},
};

pub struct RustMainViewModel(RwLock<MainViewModel>);
pub struct MainViewModel {
    tabs_map: HashMap<TabId, Tab>,
    tabs: Vec<Tab>,
    tab_groups: Vec<TabGroup>,

    tab_group_expansions: HashMap<TabGroupId, bool>,
    selected_tab: TabId,
}

impl RustMainViewModel {
    pub fn new() -> Self {
        Self(RwLock::new(MainViewModel::new()))
    }
}

#[uniffi::export]
impl RustMainViewModel {
    pub fn selected_tab(&self) -> TabId {
        self.0.read().unwrap().selected_tab.clone()
    }

    pub fn set_selected_tab(&self, selected_tab: TabId) {
        self.0.write().unwrap().select_tab(selected_tab);
    }

    pub fn tabs(&self) -> Vec<Tab> {
        self.0.read().unwrap().tabs.clone()
    }

    pub fn tabs_map(&self) -> HashMap<TabId, Tab> {
        self.0.read().unwrap().tabs_map.clone()
    }

    pub fn tab_groups(&self) -> Vec<TabGroup> {
        self.0
            .read()
            .unwrap()
            .tab_groups
            .clone()
            .into_iter()
            .collect()
    }

    pub fn tab_groups_filtered(&self, search: String) -> Vec<TabGroup> {
        if search.is_empty() {
            return self.tab_groups();
        }

        self.0
            .read()
            .unwrap()
            .tab_groups
            .iter()
            .filter_map(|tab_group| {
                let tabs = tab_group
                    .tabs
                    .iter()
                    .filter(|tab| tab.name.to_lowercase().contains(&search.to_lowercase()))
                    .cloned()
                    .collect::<Vec<Tab>>();

                if tabs.is_empty() {
                    return None;
                };

                Some(TabGroup {
                    tabs,
                    ..tab_group.clone()
                })
            })
            .collect()
    }

    pub fn tab_group_expansions(&self) -> HashMap<TabGroupId, bool> {
        self.0.read().unwrap().tab_group_expansions.clone()
    }

    pub fn set_tab_group_expansions(&self, tab_group_expansions: HashMap<TabGroupId, bool>) {
        self.0.write().unwrap().tab_group_expansions = tab_group_expansions
    }
}

impl MainViewModel {
    pub fn new() -> Self {
        let general = TabGroup::new(
            TabGroupId::General,
            vec![
                Tab::new(TabId::Cluster, "helm"),
                Tab::new(TabId::Nodes, "server.rack"),
                Tab::new(TabId::NameSpaces, "list.dash"),
                Tab::new(TabId::Events, "clock.arrow.circlepath"),
            ],
        );

        let workloads = TabGroup::new(
            TabGroupId::Workloads,
            vec![
                Tab::new(TabId::Overview, "circle"),
                Tab::new(TabId::Pods, "circle"),
                Tab::new(TabId::Deployments, "circle"),
                Tab::new(TabId::DaemonSets, "circle"),
                Tab::new(TabId::StatefulSets, "circle"),
                Tab::new(TabId::ReplicaSets, "circle"),
                Tab::new(TabId::Jobs, "circle"),
                Tab::new(TabId::CronJobs, "circle"),
            ],
        );

        let config = TabGroup::new(
            TabGroupId::Config,
            vec![
                Tab::new(TabId::ConfigMaps, "gear"),
                Tab::new(TabId::Secrets, "gear"),
                Tab::new(TabId::ResourceQuotas, "gear"),
                Tab::new(TabId::LimitRanges, "gear"),
                Tab::new(TabId::HorizontalPodAutoscalers, "gear"),
                Tab::new(TabId::PodDisruptionBudgets, "gear"),
                Tab::new(TabId::PriorityClasses, "gear"),
                Tab::new(TabId::RuntimeClasses, "gear"),
                Tab::new(TabId::Leases, "gear"),
            ],
        );

        let network = TabGroup::new(
            TabGroupId::Network,
            vec![
                Tab::new(TabId::Services, "network"),
                Tab::new(TabId::Endpoints, "network"),
                Tab::new(TabId::Ingresses, "network"),
                Tab::new(TabId::NetworkPolicies, "network"),
                Tab::new(TabId::PortForwarding, "network"),
            ],
        );

        let storage = TabGroup::new(
            TabGroupId::Storage,
            vec![
                Tab::new(TabId::PersistentVolumes, "externaldrive"),
                Tab::new(TabId::PersistentVolumeClaims, "externaldrive"),
                Tab::new(TabId::StorageClasses, "externaldrive"),
            ],
        );

        let access_control = TabGroup::new(
            TabGroupId::AccessControl,
            vec![
                Tab::new(TabId::Roles, "shield.lefthalf.filled"),
                Tab::new(TabId::RoleBindings, "shield.lefthalf.filled"),
                Tab::new(TabId::ClusterRoles, "shield.lefthalf.filled"),
                Tab::new(TabId::ClusterRoleBindings, "shield.lefthalf.filled"),
                Tab::new(TabId::ServiceAccounts, "shield.lefthalf.filled"),
                Tab::new(TabId::PodSecurityPolicies, "shield.lefthalf.filled"),
            ],
        );

        let tab_groups = vec![general, workloads, config, network, storage, access_control];

        let tabs: Vec<Tab> = tab_groups
            .iter()
            .flat_map(|tab_group| tab_group.tabs.clone())
            .collect();

        let tabs_map = tabs
            .iter()
            .map(|tab| (tab.id.clone(), tab.clone()))
            .collect();

        let tab_group_expansions = tab_groups
            .iter()
            .map(|tap_group| (tap_group.id.clone(), true))
            .collect::<HashMap<TabGroupId, bool>>();

        Self {
            tabs_map,
            tabs,
            tab_groups,
            tab_group_expansions,
            selected_tab: TabId::Cluster,
        }
    }

    pub fn select_tab(&mut self, selected_tab: TabId) {
        self.selected_tab = selected_tab
    }
}

impl Default for RustMainViewModel {
    fn default() -> Self {
        Self::new()
    }
}

impl Default for MainViewModel {
    fn default() -> Self {
        Self::new()
    }
}
