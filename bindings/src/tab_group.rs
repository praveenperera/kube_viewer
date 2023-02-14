use std::collections::HashMap;

use uniffi::Enum;

use crate::tab::Tab;
pub struct TabGroups(pub HashMap<TabGroupType, TabGroup>);

#[derive(Enum, Debug, Clone, Eq, Hash, PartialEq)]
pub enum TabGroupType {
    General,
    Workloads,
    Config,
    Network,
}

pub struct TabGroup {
    pub name: TabGroupType,
    pub tabs: Vec<Tab>,
}

impl TabGroup {
    pub fn new(name: TabGroupType, tabs: Vec<Tab>) -> Self {
        Self { name, tabs }
    }
}
