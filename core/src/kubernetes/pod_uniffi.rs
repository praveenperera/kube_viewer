use super::pod::Pod;

#[uniffi::export]
pub fn pod_preview() -> Pod {
    Pod::preview()
}

#[uniffi::export]
pub fn pod_restart_count(pod: Pod) -> i32 {
    pod.total_restart_count()
}
