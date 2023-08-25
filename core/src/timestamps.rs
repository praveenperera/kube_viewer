use chrono::{DateTime, Utc};

#[uniffi::export]
pub fn unix_to_utc_string(unix: i64) -> Option<String> {
    let naive = chrono::NaiveDateTime::from_timestamp_opt(unix, 0)?;
    let dt = DateTime::<Utc>::from_utc(naive, Utc);

    Some(dt.to_rfc3339())
}
