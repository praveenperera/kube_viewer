use derive_more::{AsRef, Display, From, FromStr};

pub mod global;
pub mod main;
pub mod node;

#[derive(Debug, Clone, AsRef, From, FromStr, Display, Hash, PartialEq, Eq)]
pub struct WindowId(String);
