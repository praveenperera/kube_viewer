use std::{collections::HashMap, sync::RwLock};

use crate::{
    tab::{Tab, TabId},
    tab_group::{TabGroup, TabGroupType, TabGroups},
};

pub struct RustMainViewModel(RwLock<MainViewModel>);
pub struct MainViewModel {
    tabs_map: HashMap<TabId, Tab>,
    tabs: Vec<Tab>,
    tab_groups: TabGroups,
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

    pub fn select_tab(&self, selected_tab: TabId) {
        self.0.write().unwrap().select_tab(selected_tab);
    }

    pub fn tabs(&self) -> Vec<Tab> {
        self.0.read().unwrap().tabs.clone()
    }

    pub fn tabs_map(&self) -> HashMap<TabId, Tab> {
        self.0.read().unwrap().tabs_map.clone()
    }
}

impl MainViewModel {
    pub fn new() -> Self {
        let general = TabGroup::new(
            TabGroupType::General,
            vec![
                Tab::new(TabId::Cluster, "steeringwheel"),
                Tab::new(TabId::Nodes, "server.rack"),
                Tab::new(TabId::NameSpaces, "list.dash"),
            ],
        );

        let workloads = TabGroup::new(
            TabGroupType::Workloads,
            vec![Tab::new(TabId::Overview, "circle")],
        );

        let config = TabGroup::new(TabGroupType::Config, vec![]);
        let network = TabGroup::new(TabGroupType::Network, vec![]);

        let tab_groups_map = maplit::hashmap! {
            TabGroupType::General => general,
            TabGroupType::Workloads => workloads,
            TabGroupType::Config => config,
            TabGroupType::Network => network
        };

        let tabs: Vec<Tab> = tab_groups_map
            .iter()
            .flat_map(|(_, tab_group)| tab_group.tabs.clone())
            .collect();

        let tabs_map = tabs
            .iter()
            .map(|tab| (tab.id.clone(), tab.clone()))
            .collect();

        Self {
            tabs_map,
            tabs,
            tab_groups: TabGroups(tab_groups_map),
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
