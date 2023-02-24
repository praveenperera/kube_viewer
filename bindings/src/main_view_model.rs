use crossbeam::channel::Sender;
use once_cell::sync::OnceCell;
use std::{collections::HashMap, sync::RwLock};

#[derive(Debug)]
pub struct Updater(Sender<MainViewModelField>);
static INSTANCE: OnceCell<Updater> = OnceCell::new();

impl Updater {
    pub fn send(field: MainViewModelField) {
        let global = INSTANCE.get().expect("updater is not initialized");
        global.0.send(field).expect("failed to send update");
    }

    pub fn init(sender: Sender<MainViewModelField>) {
        INSTANCE
            .set(Updater(sender))
            .expect("updater is already initialized");
    }
}

use crate::{
    key_handler::{FocusRegion, KeyAwareEvent, KeyHandler},
    tab::{Tab, TabId},
    tab_group::{TabGroup, TabGroupId, TabGroups},
};

#[derive(Debug, Clone, uniffi::Enum)]
pub enum MainViewModelField {
    CurrentFocusRegion,
}

pub trait MainViewModelUpdater: Send + Sync {
    fn update(&self, field: MainViewModelField);
}

pub struct RustMainViewModel(RwLock<MainViewModel>);
pub struct MainViewModel {
    key_handler: KeyHandler,
    tabs_map: HashMap<TabId, Tab>,
    tabs: Vec<Tab>,
    tab_groups: TabGroups,
    tab_group_expansions: HashMap<TabGroupId, bool>,
    selected_tab: TabId,
}

impl RustMainViewModel {
    pub fn new() -> Self {
        Self(RwLock::new(MainViewModel::new()))
    }

    pub fn add_update_listener(&self, updater: Box<dyn MainViewModelUpdater>) {
        let (sender, receiver) = crossbeam::channel::unbounded();
        Updater::init(sender);

        std::thread::spawn(move || {
            while let Ok(field) = receiver.recv() {
                updater.update(field);
            }
        });
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
            .0
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
            .0
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

    pub fn current_focus_region(&self) -> FocusRegion {
        self.0.read().unwrap().key_handler.current_focus_region()
    }

    pub fn set_current_focus_region(&self, current_focus_region: FocusRegion) {
        self.0
            .write()
            .unwrap()
            .key_handler
            .set_current_focus_region(current_focus_region);
    }

    pub fn handle_key_input(&self, key_input: KeyAwareEvent) -> bool {
        let prevent_default = self.0.write().unwrap().handle_key_input(key_input);
        Updater::send(MainViewModelField::CurrentFocusRegion);

        prevent_default
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
            key_handler: KeyHandler::new(),
            tabs_map,
            tabs,
            tab_groups: TabGroups(tab_groups),
            tab_group_expansions,
            selected_tab: TabId::Cluster,
        }
    }

    pub fn select_tab(&mut self, selected_tab: TabId) {
        self.selected_tab = selected_tab
    }

    pub fn handle_key_input(&mut self, key_input: KeyAwareEvent) -> bool {
        use FocusRegion::*;
        use KeyAwareEvent::*;

        match (&self.key_handler.current_focus_region, &key_input) {
            (SidebarGroup { id }, ShiftTab) => {
                let previous_tab_group_id = self.tab_groups.previous_tab_group_id(id);

                self.key_handler.current_focus_region = SidebarGroup {
                    id: previous_tab_group_id,
                };

                true
            }

            (SidebarGroup { id }, TabKey) => {
                let next_tab_group_id = self.tab_groups.next_tab_group_id(id);

                self.key_handler.current_focus_region = SidebarGroup {
                    id: next_tab_group_id,
                };

                true
            }

            _simple => self.key_handler.handle_key_input(&key_input),
        }
    }
}
