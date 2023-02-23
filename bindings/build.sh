#!/bin/sh

[ -z "$1" ] && BUILD_TYPE=debug
[ -z "$1" ] || BUILD_TYPE=$1

cd ../uniffi_bindgen

echo "generating bindings from udl file (${BUILD_TYPE})"
cargo run -- \
    generate ../bindings/src/kube_viewer.udl \
    --language swift \
    --out-dir ../bindings/src/generated \
    --lib-file ../bindings/target/aarch64-apple-darwin/debug/libkube_viewer.a

cd ../bindings
echo "building universal binary (${BUILD_TYPE})"
../xc-universal-binary.sh libkube_viewer.a kube_viewer "${PWD}" "$BUILD_TYPE"
