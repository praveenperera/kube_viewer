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

// uniffi::setup_scaffolding!();
uniffi::include_scaffolding!("kube_viewer");

#[derive(Debug, Clone, uniffi::Enum)]
pub enum LoadStatus {
    Initial,
    Loading,
    Loaded,
    Error { error: String },
}
