fn main() {
    uniffi::generate_scaffolding("./src/kube_viewer.udl").unwrap();
}
