#!/bin/bash

set -e

echo "***********  building android build"
pushd android/opencv-build
sh build.sh
popd
pushd ios/opencv-build
sh build.sh
popd
