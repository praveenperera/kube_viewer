use std::sync::RwLock;

use uniffi::{Enum, Record};

use crate::tab_group::TabGroupId;

#[derive(Enum)]
pub enum FocusRegion {
    SidebarSearch,
    Sidebar,
    SidebarGroup { id: TabGroupId },
    ClusterSelection,
    Content,
}

#[derive(Enum)]
pub enum KeyAwareEvent {
    UpArrow,
    DownArrow,
    LeftArrow,
    RightArrow,
    Space,
    Enter,
    ShiftTab,
}

pub struct RustKeyHandlerModel(RwLock<KeyHandlerModel>);

pub struct KeyHandlerModel {
    current_focus_region: FocusRegion,
}
