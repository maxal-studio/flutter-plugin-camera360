#!/bin/bash

set -e

OPENCV_VERSION=${1:-4.8.0}

if [ ! -d "opencv-$OPENCV_VERSION" ]; then
    curl -L https://github.com/opencv/opencv/archive/$OPENCV_VERSION.tar.gz | tar xz
fi;
if [ ! -d "opencv_contrib-$OPENCV_VERSION" ]; then
    curl -L https://github.com/opencv/opencv_contrib/archive/$OPENCV_VERSION.tar.gz | tar xz
fi;

OPENCV_BUILD_IOS_FOLDER="opencv-$OPENCV_VERSION-ios-build"
OPENCV_BUILD_OSX_FOLDER="opencv-$OPENCV_VERSION-osx-build"

rm -rf "$OPENCV_BUILD_IOS_FOLDER"

python3 "opencv-$OPENCV_VERSION/platforms/ios/build_framework.py" "$OPENCV_BUILD_IOS_FOLDER" \
    --iphoneos_deployment_target 11.0 \
    --iphoneos_archs "arm64" \
    --iphonesimulator_archs "x86_64" \
    --contrib "opencv_contrib-$OPENCV_VERSION" \
    --without dnn \
    --without ml \
    --without optflow \
    --without photo \
    --without rgbd \
    --without saliency \
    --without surface_matching \
    --without videoio \
    --without videostab \
    --without world \
    --without aruco \
    --without bgsegm \
    --without bioinspired \
    --without ccalib \
    --without dpm \
    --without fuzzy \
    --without hfs \
    --without img_hash \
    --without line_descriptor \
    --without phase_unwrapping \
    --without plot \
    --without reg \
    --without xfeatures2d \
    --without xobjdetect \
    --without xphoto \
    --without objc \
    --disable WEBP \
    --disable OPENEXR \
    --disable PROTOBUF \
    --disable IMGCODEC_SUNRASTER \
    --disable IMGCODEC_HDR \
    --disable IMGCODEC_PXM \
    --disable IMGCODEC_PFM


# The below code will build the OSX OpenCV
# rm -rf "$OPENCV_BUILD_OSX_FOLDER"

# python3 "opencv-$OPENCV_VERSION/platforms/osx/build_framework.py" "$OPENCV_BUILD_OSX_FOLDER" \
#     --contrib "opencv_contrib-$OPENCV_VERSION" \
#     --debug_info \
#     --without dnn \
#     --without ml \
#     --without optflow \
#     --without photo \
#     --without rgbd \
#     --without saliency \
#     --without stitching \
#     --without surface_matching \
#     --without videoio \
#     --without videostab \
#     --without world \
#     --without aruco \
#     --without bgsegm \
#     --without bioinspired \
#     --without ccalib \
#     --without dpm \
#     --without fuzzy \
#     --without hfs \
#     --without img_hash \
#     --without line_descriptor \
#     --without phase_unwrapping \
#     --without plot \
#     --without reg \
#     --without xfeatures2d \
#     --without xobjdetect \
#     --without xphoto \
#     --without objc \
#     --disable OPENCL \
#     --disable LAPACK \
#     --disable EIGEN
