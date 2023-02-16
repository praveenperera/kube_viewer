use uniffi::{Enum, Record};

#[derive(Debug, Clone, Eq, Hash, PartialEq, Enum)]
pub enum TabId {
    Cluster,
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
            TabId::Cluster => "Cluster".to_string(),
            TabId::Nodes => "Nodes".to_string(),
            TabId::NameSpaces => "NameSpaces".to_string(),
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
    icon: String,
    name: String,
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
