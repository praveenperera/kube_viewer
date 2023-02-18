#!/bin/sh

[ -z "$1" ] && BUILD_TYPE=debug
[ -z "$1" ] || BUILD_TYPE=$1
[ -f target/release/uniffi-bindgen ] || cargo build --features=cli --bin uniffi-bindgen --release

echo "generating bindings from udl file (${BUILD_TYPE})"
target/release/uniffi-bindgen \
    generate src/kube_viewer.udl \
    --language swift \
    --out-dir src/generated \
    --lib-file target/aarch64-apple-darwin/debug/libkube_viewer.a

echo "building universal binary (${BUILD_TYPE})"
../xc-universal-binary.sh libkube_viewer.a kube_viewer "${PWD}" "$BUILD_TYPE"
