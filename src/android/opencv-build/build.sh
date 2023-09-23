#!/bin/bash

set -e

OPENCV_VERSION=${1:-4.8.0}

NDK_ROOT=${NDK}
# NDK_ROOT=${ANDROID_NDK:-${ANDROID_NDK_HOME}}

WD=`pwd`
INSTALLDIR="${WD}/opencv-$OPENCV_VERSION-android"

rm -rf "$INSTALLDIR"

if [ ! -d "opencv-$OPENCV_VERSION" ]; then
	curl -L https://github.com/opencv/opencv/archive/$OPENCV_VERSION.tar.gz | tar xz
fi;
if [ ! -d "opencv_contrib-$OPENCV_VERSION" ]; then
	curl -L https://github.com/opencv/opencv_contrib/archive/$OPENCV_VERSION.tar.gz | tar xz
fi;

brew list ant >/dev/null || brew install ant 

for config in armeabi-v7a,16 arm64-v8a,21 x86,16 x86_64,21
do
    IFS=',' config=($config)
    ANDROID_ABI=${config[0]}
    API_LEVEL=${config[1]}

    echo "Start building ${ANDROID_ABI}, API level: ${API_LEVEL}"

    temp_build_dir="${WD}/cmake-build-opencv-${ANDROID_ABI}"
    rm -rf "${temp_build_dir}" && mkdir -p "${temp_build_dir}"

    pushd "${temp_build_dir}"
    cmake -D CMAKE_BUILD_WITH_INSTALL_RPATH=ON \
            -D ANDROID_NDK="${NDK_ROOT}" \
            -D CMAKE_TOOLCHAIN_FILE=${NDK_ROOT}/build/cmake/android.toolchain.cmake \
            -D ANDROID_NATIVE_API_LEVEL=${API_LEVEL} \
            -D ANDROID_ABI="${ANDROID_ABI}" \
            -D ANDROID_STL=c++_shared \
            -D OPENCV_EXTRA_MODULES_PATH="${WD}/opencv_contrib-$OPENCV_VERSION/modules/" \
            -D BUILD_opencv_ittnotify=OFF \
            -D BUILD_ITT=OFF \
            -D CV_DISABLE_OPTIMIZATION=ON \
            -D WITH_CUDA=OFF \
            -D WITH_OPENCL=OFF \
            -D WITH_OPENCLAMDFFT=OFF \
            -D WITH_OPENCLAMDBLAS=OFF \
            -D WITH_VA_INTEL=OFF \
            -D CPU_BASELINE_DISABLE=ON \
            -D INSTALL_CREATE_DISTRIB=ON \
            -D ENABLE_SSE=OFF \
            -D ENABLE_SSE2=OFF \
            -D BUILD_TESTING=OFF \
            -D BUILD_PERF_TESTS=OFF \
            -D BUILD_TESTS=OFF \
            -D CMAKE_BUILD_TYPE=RELEASE \
            -D BUILD_EXAMPLES=OFF \
            -D BUILD_DOCS=OFF \
            -D BUILD_opencv_apps=OFF \
            -D BUILD_SHARED_LIBS=OFF \
            -D BUILD_JAVA=OFF \
            -D BUILD_ANDROID_EXAMPLES=OFF \
            -D BUILD_ANDROID_PROJECTS=OFF \
            -D OpenCV_STATIC=ON \
            -D WITH_1394=OFF \
            -D WITH_ARITH_DEC=OFF \
            -D WITH_ARITH_ENC=OFF \
            -D WITH_CUBLAS=OFF \
            -D WITH_CUFFT=OFF \
            -D WITH_FFMPEG=OFF \
            -D WITH_GDAL=OFF \
            -D WITH_GSTREAMER=OFF \
            -D WITH_GTK=OFF \
            -D WITH_HALIDE=OFF \
            -D WITH_JASPER=OFF \
            -D WITH_NVCUVID=OFF \
            -D WITH_OPENEXR=OFF \
            -D WITH_PROTOBUF=OFF \
            -D WITH_PTHREADS_PF=OFF \
            -D WITH_QUIRC=OFF \
            -D WITH_V4L=OFF \
            -D WITH_WEBP=OFF \
            -D WITH_ADE=OFF \
            -D BUILD_LIST=core,features2d,flann,imgcodecs,imgproc,stitching \
            -D CMAKE_INSTALL_PREFIX="${INSTALLDIR}" \
            "${WD}/opencv-$OPENCV_VERSION"

    make -j20
    make install

    popd
done