use derive_more::{AsRef, Display, From, FromStr};
use serde::{Deserialize, Serialize};

pub mod global;
pub mod main;
pub mod node;

#[derive(
    Debug, Clone, AsRef, From, FromStr, Display, Hash, PartialEq, Eq, Serialize, Deserialize,
)]
pub struct WindowId(String);
