#!/bin/sh

[ -z "$1" ] && BUILD_TYPE=debug
[ -z "$1" ] || BUILD_TYPE=$1

set -e

cargo build

cd ../uniffi_bindgen

echo "generating bindings from udl file (${BUILD_TYPE})"
cargo run -- \
    generate ../core/src/kube_viewer.udl \
    --language swift \
    --out-dir ../core/src/generated \
    --lib-file ../core/target/debug/libkube_viewer.a

cd ../core
echo "building universal binary (${BUILD_TYPE})"
../xc-universal-binary.sh libkube_viewer.a kube_viewer "${PWD}" "$BUILD_TYPE"
