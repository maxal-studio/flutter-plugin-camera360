#!/bin/bash

set -e

# Build the Android framework
pushd src/android
sh build.sh
popd

# Build the iOS framework
pushd src/ios
sh build.sh
popd

# Rebuild the bindings
flutter pub run ffigen --config ffigen.yaml

# Rebuild PODS on example
pushd example/ios
pod install
popd