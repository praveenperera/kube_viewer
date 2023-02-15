use uniffi::{Enum, Record};

#[derive(Debug, Clone, Eq, Hash, PartialEq, Enum)]
pub enum TabId {
    Cluster,
    Nodes,
    NameSpaces,
    Overview,
}

impl TabId {
    fn name(&self) -> String {
        match self {
            TabId::Cluster => "Cluster".to_string(),
            TabId::Nodes => "Nodes".to_string(),
            TabId::NameSpaces => "NameSpaces".to_string(),
            TabId::Overview => "Overview".to_string(),
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
