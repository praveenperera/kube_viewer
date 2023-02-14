mod main_view_model;
mod tab;
mod tab_group;

uniffi::include_scaffolding!("kube_viewer");
use crate::main_view_model::RustMainViewModel;

mod uniffi_types {
    pub(crate) use crate::tab::*;
    pub(crate) use crate::tab_group::*;
    pub(crate) use crate::*;
}
