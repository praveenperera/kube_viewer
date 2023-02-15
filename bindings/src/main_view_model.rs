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
                Tab::new(TabId::Cluster, "steeringwheel"),
                Tab::new(TabId::Nodes, "server.rack"),
                Tab::new(TabId::NameSpaces, "list.dash"),
            ],
        );

        let workloads = TabGroup::new(
            TabGroupId::Workloads,
            vec![Tab::new(TabId::Overview, "circle")],
        );

        let config = TabGroup::new(TabGroupId::Config, vec![]);
        let network = TabGroup::new(TabGroupId::Network, vec![]);

        let tab_groups = vec![general, workloads, config, network];

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
