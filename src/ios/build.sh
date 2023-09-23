#!/bin/bash

set -e

WD=`pwd`
INSTALLDIR="build"

rm -rf "$INSTALLDIR"
mkdir "$INSTALLDIR"

# Running the cmake on CMakeLists on the same directory
pushd $INSTALLDIR
cmake ../ \
-DCMAKE_TOOLCHAIN_FILE=$WD/opencv-build/opencv-4.8.0/platforms/ios/cmake/Toolchains/Toolchain-iPhoneOS_Xcode.cmake \
  -DIOS_ARCH=arm64 \
  -DIPHONEOS_DEPLOYMENT_TARGET=11.0 \
  -DCMAKE_OSX_SYSROOT=iphoneos \
  -DCMAKE_CONFIGURATION_TYPES:=Debug \
  -GXcode


# After CMake finishes successfully, use the following Xcode command to prebuild the generated project named camera_360.xcodeproj:
xcodebuild -project camera_360.xcodeproj -target camera_360

echo "***********  Moving and cleaning after build"
rm -rf $WD/../../ios/camera_360.framework
mv $WD/build/Debug-iphoneos/camera_360.framework $WD/../../ios/camera_360.framework
echo "***********  COMPLETED"
popd
