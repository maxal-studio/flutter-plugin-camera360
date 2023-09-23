#!/bin/bash

set -e

OPENJPEG_VERSION="2.5.0"

WD=`pwd`

NDK_ROOT=${NDK}
# NDK_ROOT=${ANDROID_NDK:-${ANDROID_NDK_HOME}}

if [ -z "$INSTALLDIR" ]; then
    >&2 echo "INSTALLDIR not set"
    exit 1
fi
if [ -z "$ANDROID_ABI" ]; then
    >&2 echo "ANDROID_ABI not set"
    exit 1
fi
if [ -z "$API_LEVEL" ]; then
    >&2 echo "API_LEVEL not set"
    exit 1
fi

if [ ! -d "openjpeg-$OPENJPEG_VERSION" ]; then
    curl -L https://github.com/uclouvain/openjpeg/archive/v$OPENJPEG_VERSION.tar.gz | tar xz
fi;

temp_build_dir="cmake-build-openjpeg-${ANDROID_ABI}"
rm -rf "${temp_build_dir}" && mkdir -p "${temp_build_dir}"
pushd "${temp_build_dir}"

cmake -D CMAKE_BUILD_WITH_INSTALL_RPATH=ON \
    -D CMAKE_TOOLCHAIN_FILE=${NDK_ROOT}/build/cmake/android.toolchain.cmake \
    -D ANDROID_NDK="${NDK_ROOT}" \
    -D ANDROID_NATIVE_API_LEVEL=${API_LEVEL} \
    -D ANDROID_ABI="${ANDROID_ABI}" \
    -D ANDROID_STL="c++_shared" \
    -D BUILD_SHARED_LIBS=NO \
    -D BUILD_CODEC=NO \
    -D CMAKE_INSTALL_PREFIX="${INSTALLDIR}" \
    "${WD}/openjpeg-$OPENJPEG_VERSION"

make -j16
make install
