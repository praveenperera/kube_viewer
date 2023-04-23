pub mod generic_hasher;

mod cluster;
mod key_handler;
mod tab;
mod tab_group;

pub mod kubernetes;
pub mod task;
pub mod user_config;
pub mod view_models;

use crate::uniffi_types::*;
uniffi::include_scaffolding!("kube_viewer");

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
}
