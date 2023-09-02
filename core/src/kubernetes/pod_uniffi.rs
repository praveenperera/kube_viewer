use chrono::{Duration, Utc};
use fake::{Fake, Faker};

use crate::kubernetes::pod::ContainerStateWaiting;

use super::pod::{Container, ContainerState, ContainerStateRunning, ContainerStateTerminated, Pod};

#[uniffi::export]
pub fn pod_preview() -> Pod {
    Pod::preview()
}

#[uniffi::export]
pub fn container_preview() -> Container {
    Faker.fake()
}

#[uniffi::export]
pub fn containers_preview() -> Container {
    Faker.fake()
}

fn random_timestamp() -> i64 {
    let rand_mins = rand::random::<u32>() % 60;
    (Utc::now() - Duration::minutes(rand_mins as i64)).timestamp()
}

#[uniffi::export]
pub fn pod_container_state_running() -> ContainerState {
    ContainerState::Running {
        data: ContainerStateRunning {
            started_at: random_timestamp(),
        },
    }
}

#[uniffi::export]
pub fn pod_container_state_waiting() -> ContainerState {
    ContainerState::Waiting {
        data: ContainerStateWaiting {
            reason: Faker.fake(),
            message: Faker.fake(),
        },
    }
}

#[uniffi::export]
pub fn pod_container_state_terminated() -> ContainerState {
    ContainerState::Terminated {
        data: ContainerStateTerminated {
            started_at: random_timestamp(),
            finished_at: random_timestamp(),
            exit_code: Faker.fake(),
            message: Faker.fake(),
            reason: Faker.fake(),
            signal: Faker.fake(),
        },
    }
}
