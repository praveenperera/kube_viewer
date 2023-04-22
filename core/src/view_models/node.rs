use std::collections::HashMap;

use crossbeam::channel::Sender;
use once_cell::sync::OnceCell;
use parking_lot::RwLock;

use super::WindowId;

#[derive(Debug)]
pub struct Updater(RwLock<HashMap<WindowId, Sender<NodeViewModelField>>>);

#[allow(dead_code)]
static INSTANCE: OnceCell<Updater> = OnceCell::new();

#[derive(Debug, Clone, uniffi::Enum)]
pub enum NodeViewModelField {
    CurrentFocusRegion,
    SelectedTab,
    TabGroupExpansions,
}

pub struct RustNodeViewModel {
    inner: RwLock<NodeViewModel>,
    window_id: WindowId,
}

impl RustNodeViewModel {
    pub fn new(window_id: String) -> Self {
        let window_id = WindowId(window_id);

        Self {
            inner: RwLock::new(NodeViewModel::new(window_id.clone())),
            window_id,
        }
    }
}

#[uniffi::export]
impl RustNodeViewModel {}

pub struct NodeViewModel {
    window_id: WindowId,
}

impl NodeViewModel {
    pub fn new(window_id: WindowId) -> Self {
        Self { window_id }
    }
}
