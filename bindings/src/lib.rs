uniffi::include_scaffolding!("kube_viewer");

use std::{collections::HashMap, sync::RwLock};

#[derive(Debug, Clone, Eq, Hash, PartialEq)]
pub enum TabId {
    Cluster,
    Nodes,
    NameSpaces,
    Overview,
}

#[derive(Debug, Clone, Eq, Hash, PartialEq)]
pub struct Tab {
    id: TabId,
    icon: String,
}

#[derive(Debug, Clone, Eq, Hash, PartialEq)]

pub enum TabGroupType {
    General,
    Workloads,
    Config,
    Network,
}

pub struct TabGroup {
    name: TabGroupType,
    tabs: Vec<Tab>,
}
pub struct TabGroups(HashMap<TabGroupType, TabGroup>);

pub struct MainViewModel(RwLock<MainViewModelInner>);
pub struct MainViewModelInner {
    tab_groups: TabGroups,
    selected_tab: TabId,
}

impl Tab {
    fn new(id: TabId, icon: impl Into<String>) -> Self {
        Self {
            id,
            icon: icon.into(),
        }
    }
}

impl TabGroup {
    fn new(name: TabGroupType, tabs: Vec<Tab>) -> Self {
        Self { name, tabs }
    }
}

impl MainViewModel {
    pub fn new() -> Self {
        Self(RwLock::new(MainViewModelInner::new()))
    }

    pub fn select_tab(&self, selected_tab: TabId) {
        self.0.write().unwrap().select_tab(selected_tab);
    }
}

impl MainViewModelInner {
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

        Self {
            tab_groups: TabGroups(tab_groups_map),
            selected_tab: TabId::Cluster,
        }
    }

    pub fn select_tab(&mut self, selected_tab: TabId) {
        self.selected_tab = selected_tab
    }
}

impl Default for MainViewModel {
    fn default() -> Self {
        Self::new()
    }
}

impl Default for MainViewModelInner {
    fn default() -> Self {
        Self::new()
    }
}
