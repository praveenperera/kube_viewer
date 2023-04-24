use once_cell::sync::OnceCell;
use std::{collections::HashMap, process::Command};

static INSTANCE: OnceCell<Env> = OnceCell::new();

#[derive(Debug, Clone)]
pub struct Env {
    path: Option<String>,
}

impl Env {
    pub fn global() -> &'static Env {
        INSTANCE.get_or_init(|| {
            let env = Env::new();

            // set path from shell
            if let Some(ref path) = env.path {
                std::env::set_var("PATH", path);
            }

            env
        })
    }
}

impl Env {
    fn new() -> Self {
        let default_shell = std::env::var("SHELL").unwrap_or_else(|_| "/bin/zsh".to_string());

        let output = Command::new(default_shell)
            .arg("-ilc")
            .arg("env")
            .output()
            .unwrap()
            .stdout;

        let env = String::from_utf8(output).unwrap();
        let env_hashmap = parse_env(&env);

        Env {
            path: env_hashmap.get("PATH").cloned(),
        }
    }
}

fn parse_env(env: &str) -> HashMap<String, String> {
    env.lines()
        .filter_map(|line| {
            if line.is_empty() {
                return None;
            }

            let mut parts = line.splitn(2, '=');
            let key = parts.next()?.trim();
            let value = parts.next()?.trim();

            Some((key.to_string(), value.to_string()))
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_env() {
        let env = r#"
            USER=praveen
            HOMEBREW_PREFIX=/opt/homebrew
            HOMEBREW_CELLAR=/opt/homebrew/Cellar
            HOMEBREW_REPOSITORY=/opt/homebrew
            FNM_DIR=/Users/praveen/Library/Application Support/fnm
            FNM_NODE_DIST_MIRROR=https://nodejs.org/dist
            FNM_ARCH=arm64
            FNM_MULTISHELL_PATH=/Users/praveen/Library/Caches/fnm_multishells/5532_1682350032728:/bin/sh
            FNM_VERSION_FILE_STRATEGY=local
            FNM_LOGLEVEL=info
        "#;

        let parsed_env = parse_env(env);

        assert_eq!(parsed_env.get("USER").unwrap(), "praveen");
        assert_eq!(parsed_env.get("HOMEBREW_PREFIX").unwrap(), "/opt/homebrew");
        assert_eq!(
            parsed_env.get("FNM_MULTISHELL_PATH").unwrap(),
            "/Users/praveen/Library/Caches/fnm_multishells/5532_1682350032728:/bin/sh"
        )
    }
}
