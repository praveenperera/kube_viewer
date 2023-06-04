use std::path::PathBuf;

use act_zero::*;
use notify::{RecursiveMode, Watcher};

use crate::view_models::global;

pub struct KubeConfigWatcher {
    addr: WeakAddr<Self>,
    global_worker: WeakAddr<global::Worker>,
    status: KubeConfigStatus,
}

pub enum KubeConfigStatus {
    ExistsEnv(Vec<PathBuf>),
    ExistsDefault(PathBuf),
    NotPresent,
}

impl KubeConfigWatcher {
    pub fn new(global_worker: WeakAddr<global::Worker>) -> Self {
        Self {
            addr: Default::default(),
            global_worker,
            status: KubeConfigStatus::new(),
        }
    }

    pub fn start_watcher(&mut self) -> ActorResult<()> {
        match &self.status {
            KubeConfigStatus::ExistsEnv(paths) => {
                for path in paths {
                    let path = path.to_owned();
                    let global_worker = self.global_worker.clone();

                    self.addr
                        .send_fut(async move { watch_path_and_notify(path, global_worker) });
                }
            }

            KubeConfigStatus::ExistsDefault(path) => {
                let path = path.to_owned();
                let global_worker = self.global_worker.clone();

                self.addr
                    .send_fut(async move { watch_path_and_notify(path, global_worker) });
            }

            KubeConfigStatus::NotPresent => {
                log::warn!("KUBECONFIG not set, and no default config found, polling every 30 seconds for chagnes");
                let global_worker = self.global_worker.clone();

                self.addr.send_fut(async move {
                    loop {
                        tokio::time::sleep(std::time::Duration::from_secs(30)).await;

                        if !matches!(KubeConfigStatus::new(), KubeConfigStatus::NotPresent) {
                            // new config found, stop polling, start a new watcher
                            send!(global_worker.start_new_kube_config_watcher());
                            break;
                        }
                    }
                })
            }
        }

        Produces::ok(())
    }
}

impl Default for KubeConfigStatus {
    fn default() -> Self {
        Self::new()
    }
}

impl KubeConfigStatus {
    pub fn new() -> Self {
        if let Some(paths) = Self::get_paths_from_env() {
            return Self::ExistsEnv(paths);
        }

        if let Some(path) = Self::get_from_default_path() {
            return Self::ExistsDefault(path);
        }

        Self::NotPresent
    }

    fn get_paths_from_env() -> Option<Vec<PathBuf>> {
        if let Some(value) = std::env::var_os("KUBECONFIG") {
            let paths = std::env::split_paths(&value)
                .filter(|p| !p.as_os_str().is_empty())
                .collect::<Vec<_>>();

            if paths.is_empty() {
                return None;
            }

            Some(paths)
        } else {
            None
        }
    }

    fn get_from_default_path() -> Option<PathBuf> {
        let path = Self::default_kube_path()?;

        if path.exists() {
            return Some(path);
        }

        None
    }

    fn default_kube_path() -> Option<PathBuf> {
        use etcetera::home_dir;
        home_dir().map(|h| h.join(".kube").join("config")).ok()
    }
}

#[async_trait::async_trait]
impl Actor for KubeConfigWatcher {
    async fn started(&mut self, addr: Addr<Self>) -> ActorResult<()> {
        self.addr = addr.downgrade();
        Produces::ok(())
    }

    async fn error(&mut self, error: ActorError) -> bool {
        log::error!("KubeConfigWatcher Actor Error: {error:?}");
        false
    }
}

pub fn watch_path_and_notify(path: PathBuf, global_worker: WeakAddr<global::Worker>) {
    let mut watcher = notify::recommended_watcher(move |res| match res {
        Ok(_event) => {
            send!(global_worker.reload_clusters());
        }
        Err(e) => log::error!("watch error: {:?}", e),
    })
    .expect("failed to create watcher");

    watcher
        .watch(&path, RecursiveMode::NonRecursive)
        .expect("failed to watch path");
}
