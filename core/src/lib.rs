pub mod generic_hasher;

mod key_handler;
mod main_view_model;
mod tab;
mod tab_group;

use crate::uniffi_types::*;
uniffi::include_scaffolding!("kube_viewer");

mod uniffi_types {
    pub(crate) use crate::key_handler::*;
    pub(crate) use crate::main_view_model::*;
    pub(crate) use crate::tab::*;
    pub(crate) use crate::tab_group::*;
}
