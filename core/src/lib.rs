pub mod generic_hasher;

mod cluster;
mod key_handler;
mod tab;
mod tab_group;

pub mod env;
pub mod kubernetes;
pub mod task;
pub mod user_config;
pub mod view_models;

use crate::uniffi_types::*;
uniffi::include_scaffolding!("kube_viewer");

#[derive(Debug, Clone, uniffi::Enum)]
pub enum LoadStatus {
    Initial,
    Loading,
    Loaded,
    Error { error: String },
}

mod uniffi_types {
    // view models
    pub(crate) use crate::view_models::global::*;
    pub(crate) use crate::view_models::main::*;
    pub(crate) use crate::view_models::node::*;

    // view model helpers
    pub(crate) use crate::key_handler::*;

    pub(crate) use crate::cluster::*;
    pub(crate) use crate::tab::*;
    pub(crate) use crate::tab_group::*;

    pub(crate) use crate::kubernetes::node::*;

    pub(crate) use crate::LoadStatus;
}
