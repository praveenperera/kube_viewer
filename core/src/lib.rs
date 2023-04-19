pub mod generic_hasher;

mod cluster;
mod global_view_model;
mod key_handler;
mod main_view_model;
mod tab;
mod tab_group;
pub mod user_config;

use crate::uniffi_types::*;
uniffi::include_scaffolding!("kube_viewer");

mod uniffi_types {
    // view models
    pub(crate) use crate::global_view_model::*;
    pub(crate) use crate::main_view_model::*;

    // view model helpers
    pub(crate) use crate::key_handler::*;

    pub(crate) use crate::cluster::*;
    pub(crate) use crate::tab::*;
    pub(crate) use crate::tab_group::*;
}
