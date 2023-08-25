pub mod generic_hasher;

mod cluster;
mod key_handler;
mod tab;
mod tab_group;

pub mod env;
pub mod kubernetes;
pub mod task;
pub mod timestamps;
pub mod user_config;
pub mod view_models;

uniffi::include_scaffolding!("kube_viewer");

use std::fmt::Display;

use crate::key_handler::FocusRegionHasher;
use crate::view_models::node::RustNodeViewModel;

#[derive(Debug, Clone, uniffi::Enum)]
pub enum SimpleLoadStatus {
    Initial,
    Loading,
    Loaded,
    Error { error: String },
}

#[derive(Debug, Clone)]
pub enum LoadStatus<T, E: Display> {
    Initial,
    Loading,
    Loaded(T),
    Error(E),
}
