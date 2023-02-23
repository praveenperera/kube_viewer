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

#[derive(Debug, Clone, Eq, Hash, PartialEq)]
pub struct TabGroups(pub Vec<TabGroup>);

impl TabGroups {
    pub fn next_tab_group_id(&self, id: &TabGroupId) -> TabGroupId {
        let current_index = self.get_index_by_id(id).unwrap_or(0);
        let next_index = if current_index == (self.0.len() - 1) {
            0
        } else {
            current_index + 1
        };

        self.0[next_index].id.clone()
    }

    pub fn previous_tab_group_id(&self, id: &TabGroupId) -> TabGroupId {
        let current_index = self.get_index_by_id(id).unwrap_or(0);
        let previous_tab_index = if current_index == 0 {
            (self.0.len().min(1)) - 1
        } else {
            current_index - 1
        };

        self.0[previous_tab_index].id.clone()
    }

    fn get_index_by_id(&self, id: &TabGroupId) -> Option<usize> {
        self.0.iter().position(|tab_group| &tab_group.id == id)
    }
}
