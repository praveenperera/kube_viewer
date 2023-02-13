uniffi::include_scaffolding!("math");

pub fn add(left: usize, right: usize) -> usize {
    left + right
}
