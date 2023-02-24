use uniffi::Enum;

use crate::tab_group::TabGroupId;

#[derive(Debug, Clone, Enum)]
pub enum FocusRegion {
    SidebarSearch,
    SidebarGroup { id: TabGroupId },
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

    pub fn handle_key_input(&mut self, key_input: &KeyAwareEvent) -> bool {
        use FocusRegion::*;
        use KeyAwareEvent::*;

        match (&self.current_focus_region, key_input) {
            (Content, TabKey) => {
                self.current_focus_region = SidebarSearch;
                true
            }
            _ => false,
        }
    }
}
