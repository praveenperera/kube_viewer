use uniffi::Enum;

use crate::{generic_hasher::GenericHasher, tab::TabId, tab_group::TabGroupId};

#[derive(Debug, Clone, Enum, Hash)]
pub enum FocusRegion {
    SidebarSearch,
    SidebarGroup {
        id: TabGroupId,
    },
    InTabGroup {
        tab_group_id: TabGroupId,
        tab_id: TabId,
    },
    ClusterSelection,
    Content,
}

#[derive(Debug, Clone, Enum)]
pub enum KeyAwareEvent {
    Delete,
    UpArrow,
    DownArrow,
    LeftArrow,
    RightArrow,
    Space,
    Enter,
    ShiftTab,
    TabKey,
    Escape,
}

#[derive(Debug, Clone)]
pub struct KeyHandler {
    pub current_focus_region: FocusRegion,
}

impl KeyHandler {
    pub fn new() -> Self {
        Self {
            current_focus_region: FocusRegion::SidebarGroup {
                id: TabGroupId::General,
            },
        }
    }

    pub fn current_focus_region(&self) -> FocusRegion {
        self.current_focus_region.clone()
    }

    pub fn set_current_focus_region(&mut self, focus_region: FocusRegion) {
        self.current_focus_region = focus_region
    }
}

pub struct FocusRegionHasher(GenericHasher<FocusRegion>);

impl FocusRegionHasher {
    pub fn new() -> Self {
        Self(GenericHasher::new())
    }
}

#[uniffi::export]
impl FocusRegionHasher {
    fn hash(&self, value: FocusRegion) -> u64 {
        self.0.hash(value)
    }
}
