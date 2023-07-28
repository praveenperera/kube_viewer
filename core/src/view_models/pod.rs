use crate::kubernetes::pod::Pod;

#[derive(uniffi::Enum)]
pub enum PodLoadStatus {
    Initial,
    Loading,
    Loaded { nodes: Vec<Pod> },
    Error { error: String },
}
