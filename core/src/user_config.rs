use etcetera::app_strategy::{self, AppStrategy, AppStrategyArgs, Xdg};
use eyre::{Context, Result};
use once_cell::sync::Lazy;

use crate::cluster::ClusterId;

pub static APP_DIR: Lazy<Xdg> = Lazy::new(|| {
    let app_strategy_args = AppStrategyArgs {
        top_level_domain: "com".to_string(),
        author: "infraopssolutions".to_string(),
        app_name: "kube-viewer-app".to_string(),
    };

    app_strategy::Xdg::new(app_strategy_args).expect("failed to create app strategy directory")
});

#[derive(serde::Serialize, serde::Deserialize, Debug, Clone)]
pub struct UserConfig {
    pub selected_cluster: Option<ClusterId>,
}

impl Default for UserConfig {
    fn default() -> Self {
        Self::new()
    }
}

impl UserConfig {
    pub fn new() -> Self {
        Self {
            selected_cluster: None,
        }
    }

    pub fn load() -> Self {
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

    pub fn set_selected_cluster(&mut self, cluster_id: ClusterId) -> Result<()> {
        self.selected_cluster = Some(cluster_id);
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
