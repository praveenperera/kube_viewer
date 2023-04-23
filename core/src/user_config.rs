use std::collections::HashMap;

use etcetera::app_strategy::{self, AppStrategy, AppStrategyArgs, Xdg};
use eyre::{Context, Result};
use once_cell::sync::Lazy;
use parking_lot::RwLock;
use serde::{Deserialize, Serialize};

use crate::{cluster::ClusterId, view_models::WindowId};

pub static APP_DIR: Lazy<Xdg> = Lazy::new(|| {
    let app_strategy_args = AppStrategyArgs {
        top_level_domain: "com".to_string(),
        author: "infraopssolutions".to_string(),
        app_name: "kube-viewer-app".to_string(),
    };

    app_strategy::Xdg::new(app_strategy_args).expect("failed to create app strategy directory")
});

pub static USER_CONFIG: Lazy<RwLock<UserConfig>> = Lazy::new(|| RwLock::new(UserConfig::load()));

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct UserConfig {
    pub window_configs: HashMap<WindowId, WindowConfig>,
}

#[derive(Serialize, Deserialize, Debug, Clone, Default)]
pub struct WindowConfig {
    pub selected_cluster: Option<ClusterId>,
}

impl Default for UserConfig {
    fn default() -> Self {
        Self::new()
    }
}

impl UserConfig {
    fn new() -> Self {
        Self {
            window_configs: HashMap::new(),
        }
    }

    fn load() -> Self {
        let config_path = APP_DIR.config_dir().join("user_config.json");

        // create config file if it doesn't exist
        if !config_path.exists() {
            let config_dir = config_path.parent().expect("failed to get config dir");
            std::fs::create_dir_all(config_dir).expect("failed to create config dir");

            let config = Self::new();

            if let Err(err) = config.save() {
                eprintln!("failed to save config file: {err}");
            }

            return config;
        }

        let config_str = std::fs::read_to_string(config_path).expect("failed to read config file");
        serde_json::from_str(&config_str).expect("failed to parse config file")
    }

    pub fn get_selected_cluster(&self, window_id: &WindowId) -> Option<ClusterId> {
        self.window_configs.get(window_id)?.selected_cluster.clone()
    }

    pub fn set_selected_cluster(
        &mut self,
        window_id: WindowId,
        cluster_id: ClusterId,
    ) -> Result<()> {
        self.window_configs
            .entry(window_id)
            .or_insert_with(WindowConfig::default)
            .selected_cluster = Some(cluster_id);

        self.save()
    }

    pub fn save(&self) -> Result<()> {
        let config_path = APP_DIR.config_dir().join("user_config.json");
        let config_str =
            serde_json::to_string_pretty(self).wrap_err("failed to serialize config")?;

        std::fs::write(config_path, config_str).wrap_err("failed to write config file")?;

        Ok(())
    }
}
