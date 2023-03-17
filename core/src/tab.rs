use uniffi::{Enum, Record};

#[derive(Debug, Clone, Eq, Hash, PartialEq, Enum)]
pub enum TabId {
    ClusterTab,
    Nodes,
    NameSpaces,
    Events,
    Overview,
    Pods,
    Deployments,
    DaemonSets,
    StatefulSets,
    ReplicaSets,
    Jobs,
    CronJobs,
    ConfigMaps,
    Secrets,
    ResourceQuotas,
    LimitRanges,
    HorizontalPodAutoscalers,
    PodDisruptionBudgets,
    PriorityClasses,
    RuntimeClasses,
    Leases,
    Services,
    Endpoints,
    Ingresses,
    NetworkPolicies,
    PortForwarding,
    PersistentVolumeClaims,
    PersistentVolumes,
    StorageClasses,
    ServiceAccounts,
    ClusterRoles,
    Roles,
    ClusterRoleBindings,
    RoleBindings,
    PodSecurityPolicies,
    Charts,
    Releases,
}

impl TabId {
    fn name(&self) -> String {
        match self {
            TabId::ClusterTab => "Cluster".to_string(),
            TabId::Nodes => "Nodes".to_string(),
            TabId::NameSpaces => "Namespaces".to_string(),
            TabId::Events => "Events".to_string(),
            TabId::Overview => "Overview".to_string(),
            TabId::Pods => "Pods".to_string(),
            TabId::Deployments => "Deployments".to_string(),
            TabId::DaemonSets => "DaemonSets".to_string(),
            TabId::StatefulSets => "StatefulSets".to_string(),
            TabId::ReplicaSets => "ReplicaSets".to_string(),
            TabId::Jobs => "Jobs".to_string(),
            TabId::CronJobs => "Cron Jobs".to_string(),
            TabId::ConfigMaps => "Config Maps".to_string(),
            TabId::Secrets => "Secrets".to_string(),
            TabId::ResourceQuotas => "Resource Quotas".to_string(),
            TabId::LimitRanges => "Limit Ranges".to_string(),
            TabId::HorizontalPodAutoscalers => "HPA".to_string(),
            TabId::PodDisruptionBudgets => "Pod Disruption Budgets".to_string(),
            TabId::PriorityClasses => "Priority Classes".to_string(),
            TabId::RuntimeClasses => "Runtime Classes".to_string(),
            TabId::Leases => "Leases".to_string(),
            TabId::Services => "Services".to_string(),
            TabId::Endpoints => "Endpoints".to_string(),
            TabId::Ingresses => "Ingresses".to_string(),
            TabId::NetworkPolicies => "Network Policies".to_string(),
            TabId::PortForwarding => "Port Forwarding".to_string(),
            TabId::PersistentVolumeClaims => "Persistent Volume Claims".to_string(),
            TabId::PersistentVolumes => "Persistent Volumes".to_string(),
            TabId::StorageClasses => "Storage Classes".to_string(),
            TabId::ServiceAccounts => "Service Accounts".to_string(),
            TabId::ClusterRoles => "Cluster Roles".to_string(),
            TabId::Roles => "Roles".to_string(),
            TabId::ClusterRoleBindings => "Cluster Role Bindings".to_string(),
            TabId::RoleBindings => "Role Bindings".to_string(),
            TabId::PodSecurityPolicies => "Pod Security Policies".to_string(),
            TabId::Charts => "Charts".to_string(),
            TabId::Releases => "Releases".to_string(),
        }
    }
}

#[derive(Debug, Clone, Eq, Hash, PartialEq, Record)]
pub struct Tab {
    pub id: TabId,
    pub icon: String,
    pub name: String,
}

impl Tab {
    pub fn new(id: TabId, icon: impl Into<String>) -> Self {
        Self {
            name: id.name(),
            id,
            icon: icon.into(),
        }
    }
}

#[derive(Debug, Clone, Eq, Hash, PartialEq)]
pub struct Tabs(Vec<Tab>);

#[derive(Debug, Clone, Eq, Hash, PartialEq)]
pub struct BorrowedTabs<'a>(&'a Vec<Tab>);

impl<'a> BorrowedTabs<'a> {
    pub fn next_tab_id(&self, id: &TabId) -> Option<TabId> {
        let current_index = self.get_index_by_id(id).unwrap_or(0);
        if current_index == (self.0.len() - 1) {
            return None;
        };

        let next_index = current_index + 1;
        Some(self.0[next_index].id.clone())
    }

    pub fn previous_tab_id(&self, id: &TabId) -> Option<TabId> {
        let current_index = self.get_index_by_id(id).unwrap_or(0);
        if current_index == 0 {
            return None;
        }

        let previous_tab_index = current_index - 1;
        Some(self.0[previous_tab_index].id.clone())
    }

    #[allow(dead_code)]
    pub fn get_by_id(&self, id: &TabId) -> Option<&Tab> {
        self.0.iter().find(|tab| &tab.id == id)
    }

    pub fn get_index_by_id(&self, id: &TabId) -> Option<usize> {
        self.0.iter().position(|tab| &tab.id == id)
    }
}

impl From<Vec<Tab>> for Tabs {
    fn from(value: Vec<Tab>) -> Self {
        Tabs(value)
    }
}

impl<'a> From<&'a Vec<Tab>> for BorrowedTabs<'a> {
    fn from(value: &'a Vec<Tab>) -> Self {
        BorrowedTabs(value)
    }
}

impl<'a> From<&'a Tabs> for BorrowedTabs<'a> {
    fn from(value: &'a Tabs) -> Self {
        BorrowedTabs(&value.0)
    }
}
