#!/bin/bash

set -e

WD=`pwd`
INSTALLDIR="build"

rm -rf "$INSTALLDIR"
mkdir "$INSTALLDIR"

pushd $INSTALLDIR
rm -rf $WD/../../android/src/lib/*  #make sure that you are not deleting your other libraries

for config in armeabi-v7a,16 arm64-v8a,21 x86,16 x86_64,21
do
IFS=',' config=($config)
arch=${config[0]}
min_platform=${config[1]}
#clean everything in build folder
rm -rf *
#prepare cmake project for ninja builder
cmake ../ \
-DCMAKE_TOOLCHAIN_FILE=$NDK/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI="${arch}" \
  -DANDROID_PLATFORM="${min_platform}" \
  -DANDROID_STL=c++_static \
  -DANDROID_TOOLCHAIN=clang \
  -DCMAKE_BUILD_TYPE:=Release \
  -GNinja
#build library with ninja
ninja -j16

echo "***********  Moving library and cleaning after build"
mkdir -p $WD/../../android/src/lib/${arch}
mv $WD/build/libcamera_360.so $WD/../../android/src/lib/"${arch}"/libcamera_360.so
echo "***********  COMPLETED"
done

popd
