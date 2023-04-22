use std::{collections::hash_map::DefaultHasher, hash::Hash, marker::PhantomData};

pub struct GenericHasher<T: Hash> {
    _phantom: PhantomData<T>,
}

impl<T: Hash> GenericHasher<T> {
    pub(crate) fn new() -> Self {
        Self {
            _phantom: PhantomData,
        }
    }

    pub fn hash(&self, value: T) -> u64 {
        use std::hash::Hasher;

        let mut hasher = DefaultHasher::new();
        value.hash(&mut hasher);
        hasher.finish()
    }
}
