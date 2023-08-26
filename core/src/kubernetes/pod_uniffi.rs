use fake::{Fake, Faker};

use super::pod::{Container, Pod};

#[uniffi::export]
pub fn pod_preview() -> Pod {
    Pod::preview()
}

#[uniffi::export]
pub fn pod_restart_count(pod: Pod) -> i32 {
    pod.total_restart_count()
}

#[uniffi::export]
pub fn container_preview() -> Container {
    Faker.fake()
}

#[uniffi::export]
pub fn containers_preview() -> Vec<Container> {
    Faker.fake()
}
