#!/bin/bash

[ -z "$1" ] && BUILD_TYPE=debug
[ -z "$1" ] || BUILD_TYPE=$1

echo "BUILD TYPE $BUILD_TYPE"

../xc-universal-binary.sh libkube_viewer.a kube_viewer "${PWD}" "$BUILD_TYPE"

cargo run --features=cli --bin uniffi-bindgen \
    generate src/kube_viewer.udl \
    --language swift \
    --out-dir src/generated \
    --lib-file target/aarch64-apple-darwin/debug/libkube_viewer.a
