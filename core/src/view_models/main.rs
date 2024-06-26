mod key_handler;

use act_zero::send;
use crossbeam::channel::Sender;
use log::{debug, error};
use once_cell::sync::OnceCell;
use parking_lot::RwLock;
use std::{collections::HashMap, sync::Arc};

use crate::{
    cluster::{Cluster, ClusterId},
    key_handler::{FocusRegion, KeyAwareEvent, KeyHandler},
    tab::{Tab, TabId},
    tab_group::{TabGroup, TabGroupId, TabGroups},
    user_config::USER_CONFIG,
};

use super::{global::GlobalViewModel, WindowId};

#[derive(Debug)]
pub struct Updater(RwLock<HashMap<WindowId, Sender<MainViewModelField>>>);
static INSTANCE: OnceCell<Updater> = OnceCell::new();

impl Updater {
    pub fn send(window_id: &WindowId, field: MainViewModelField) {
        let global = INSTANCE.get().expect("updater is not initialized");

        if let Some(updater) = global.0.read().get(window_id) {
            updater.send(field).expect("failed to send update");
        }
    }

    pub fn init(window_id: &WindowId, sender: Sender<MainViewModelField>) {
        debug!("init updater for window {window_id:?}");
        let map = INSTANCE.get_or_init(|| Updater(RwLock::new(HashMap::new())));
        map.0.write().insert(window_id.clone(), sender);
    }
}

#[derive(Debug, Clone, uniffi::Enum)]
pub enum MainViewModelField {
    CurrentFocusRegion {
        focus_region: FocusRegion,
    },
    SelectedTab {
        tab_id: TabId,
    },
    TabGroupExpansions {
        expansions: HashMap<TabGroupId, bool>,
    },
}

#[uniffi::export(callback_interface)]
pub trait MainViewModelUpdater: Send + Sync {
    fn update(&self, field: MainViewModelField);
}

#[derive(uniffi::Object)]
pub struct RustMainViewModel {
    inner: RwLock<MainViewModel>,
    window_id: WindowId,
}
pub struct MainViewModel {
    window_id: WindowId,
    key_handler: KeyHandler,
    selected_cluster: Option<ClusterId>,
    tabs_map: HashMap<TabId, Tab>,
    tabs: Vec<Tab>,
    tab_groups: TabGroups,
    tab_group_expansions: HashMap<TabGroupId, bool>,
    selected_tab: TabId,
    search: Option<String>,
}

#[uniffi::export(async_runtime = "tokio")]
impl RustMainViewModel {
    #[uniffi::constructor]
    pub fn new(window_id: String) -> Arc<Self> {
        Arc::new(Self {
            inner: RwLock::new(MainViewModel::new(window_id.clone().into())),
            window_id: window_id.into(),
        })
    }

    pub async fn async_do(&self) {
        debug!("async_do");
    }

    pub fn add_update_listener(&self, updater: Box<dyn MainViewModelUpdater>) {
        let (sender, receiver) = crossbeam::channel::unbounded();
        Updater::init(&self.window_id, sender);

        std::thread::spawn(move || {
            while let Ok(field) = receiver.recv() {
                updater.update(field);
            }
        });
    }

    pub fn selected_tab(&self) -> TabId {
        self.inner.read().selected_tab.clone()
    }

    pub fn set_window_closed(&self) {
        let _ = USER_CONFIG.write().clear_window_config(&self.window_id);
    }

    pub fn set_selected_tab(&self, selected_tab: TabId) {
        self.inner.write().select_tab(selected_tab);
    }

    pub fn tabs(&self) -> Vec<Tab> {
        self.inner.read().tabs.clone()
    }

    pub fn tabs_map(&self) -> HashMap<TabId, Tab> {
        self.inner.read().tabs_map.clone()
    }

    pub fn tab_groups_filtered(&self, search: String) -> Vec<TabGroup> {
        self.inner.write().search = if search.is_empty() {
            None
        } else {
            Some(search.clone())
        };

        self.inner.read().tab_groups_filtered().0
    }

    pub fn select_first_filtered_tab(&self) {
        if self.inner.write().set_first_filtered_tab().is_none() {
            return;
        }

        Updater::send(
            &self.window_id,
            MainViewModelField::SelectedTab {
                tab_id: self.selected_tab(),
            },
        );
    }

    pub fn tab_group_expansions(&self) -> HashMap<TabGroupId, bool> {
        self.inner.read().tab_group_expansions.clone()
    }

    pub fn set_tab_group_expansions(&self, tab_group_expansions: HashMap<TabGroupId, bool>) {
        self.inner.write().tab_group_expansions = tab_group_expansions
    }

    pub fn current_focus_region(&self) -> FocusRegion {
        self.inner.read().key_handler.current_focus_region()
    }

    pub fn set_current_focus_region(&self, current_focus_region: FocusRegion) {
        log::debug!("setting current_focus to: {current_focus_region:?}");

        self.inner
            .write()
            .key_handler
            .set_current_focus_region(current_focus_region);
    }

    pub fn selected_cluster(&self) -> Option<Cluster> {
        self.inner.read().selected_cluster()
    }

    pub fn set_selected_cluster(&self, cluster: Cluster) {
        if GlobalViewModel::global()
            .read()
            .get_cluster(&cluster.id)
            .is_none()
        {
            // cluster does not exist in kubeconfig clusters, do not set it as selected
            return;
        }

        self.inner.write().selected_cluster = Some(cluster.id.clone());

        // load client for selected cluster in the background
        let global_view_model = GlobalViewModel::global().read();
        send!(global_view_model.worker.load_client(cluster.id.clone()));

        if let Err(err) = USER_CONFIG
            .write()
            .set_selected_cluster(self.window_id.clone(), cluster.id)
        {
            error!("failed to set selected cluster: {err}");
        }
    }

    pub fn handle_key_input(&self, key_input: KeyAwareEvent) -> bool {
        let prevent_default = self.inner.write().handle_key_input(key_input);
        Updater::send(
            &self.window_id,
            MainViewModelField::CurrentFocusRegion {
                focus_region: self.current_focus_region(),
            },
        );

        prevent_default
    }
}

impl MainViewModel {
    pub fn new(window_id: WindowId) -> Self {
        let general = TabGroup::new(
            TabGroupId::General,
            vec![
                Tab::new(TabId::ClusterTab, "helm"),
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

        // maybe selected_cluster from user config
        let selected_cluster = USER_CONFIG.read().get_selected_cluster(&window_id);

        // selected cluster if it exists in kube_config, if not current context
        let selected_cluster_checked = GlobalViewModel::global()
            .read()
            .clusters
            .as_ref()
            .and_then(|clusters| clusters.selected_or_context_cluster(selected_cluster));

        if let Some(selected_cluster) = selected_cluster_checked.as_ref() {
            // load client for selected cluster in the background
            let global_view_model = GlobalViewModel::global().read();
            send!(global_view_model
                .worker
                .load_client(selected_cluster.clone()))
        }

        Self {
            window_id,
            selected_cluster: selected_cluster_checked,
            key_handler: KeyHandler::new(),
            tabs_map,
            tabs,
            tab_groups: TabGroups(tab_groups),
            tab_group_expansions,
            selected_tab: TabId::ClusterTab,
            search: None,
        }
    }

    pub fn selected_cluster(&self) -> Option<Cluster> {
        let cluster_id = &self.selected_cluster.as_ref()?;

        GlobalViewModel::global()
            .read()
            .clusters
            .as_ref()?
            .get_cluster(cluster_id)
    }

    pub fn select_tab(&mut self, selected_tab: TabId) {
        self.selected_tab = selected_tab;
        self.expand_selected_tabs_tab_group();
    }

    pub fn tab_groups_filtered(&self) -> TabGroups {
        if self.search.is_none() {
            return self.tab_groups.clone();
        }

        let search = self.search.as_ref().expect("just checked search exists");

        let tab_groups = self
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
            .collect::<Vec<TabGroup>>();

        TabGroups(tab_groups)
    }

    pub fn set_first_filtered_tab(&mut self) -> Option<()> {
        let tab = self.get_first_filtered_tab()?;
        self.select_tab(tab);

        Some(())
    }

    pub fn get_first_filtered_tab(&self) -> Option<TabId> {
        let search = self.search.as_ref()?;

        if search.is_empty() {
            return None;
        }

        let tab_groups = self.tab_groups_filtered().0;

        Some(tab_groups.first()?.tabs.first()?.id.clone())
    }

    pub fn expand_selected_tabs_tab_group(&mut self) -> Option<()> {
        let tab_group_id = self
            .tab_groups
            .get_by_tab_id(&self.selected_tab)?
            .id
            .clone();

        if let Some(expanded @ false) = self.tab_group_expansions.get_mut(&tab_group_id) {
            *expanded = true;

            Updater::send(
                &self.window_id,
                MainViewModelField::TabGroupExpansions {
                    expansions: self.tab_group_expansions.clone(),
                },
            );
        }

        Some(())
    }
}
