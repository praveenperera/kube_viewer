use uniffi::{Enum, Record};

use crate::tab::Tab;

#[derive(Enum, Debug, Clone, Eq, Hash, PartialEq)]
pub enum TabGroupId {
    General,
    Workloads,
    Config,
    Network,
    Storage,
    AccessControl,
    Helm,
}

impl TabGroupId {
    fn name(&self) -> String {
        match self {
            TabGroupId::General => "General".to_string(),
            TabGroupId::Workloads => "Workloads".to_string(),
            TabGroupId::Config => "Config".to_string(),
            TabGroupId::Network => "Network".to_string(),
            TabGroupId::Storage => "Storage".to_string(),
            TabGroupId::AccessControl => "Access Control".to_string(),
            TabGroupId::Helm => "Helm".to_string(),
        }
    }
}

#[derive(Debug, Clone, Eq, Hash, PartialEq, Record)]
pub struct TabGroup {
    pub id: TabGroupId,
    pub name: String,
    pub tabs: Vec<Tab>,
}

impl TabGroup {
    pub fn new(id: TabGroupId, tabs: Vec<Tab>) -> Self {
        let name = id.name();

        Self { id, name, tabs }
    }
}
