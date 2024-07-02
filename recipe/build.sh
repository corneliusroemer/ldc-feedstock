#!/bin/bash
set -eu -o pipefail
set -x

BOOTSTRAP=false
if [[ "${build_platform}" == "osx-arm64" ]]; then
    BOOTSTRAP=true
fi

# In the future we can just use mamba install to get a previous version on all platforms
if [[ $BOOTSTRAP ]]; then
    LDC_VERSION=1.38.0 # Try using newest version first
    curl -fsS https://dlang.org/install.sh | bash -s ldc-$LDC_VERSION
    source ~/dlang/ldc-$LDC_VERSION/activate
    ldc2 -version
    DCMP=ldmd2
else
    mamba install -y ldc -p ${BUILD_PREFIX}
    DCMP=${BUILD_PREFIX}/bin/ldmd2
fi

mkdir build
cd build
cmake -G Ninja \
    ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -DBUILD_SHARED_LIBS=ON \
    -DD_COMPILER=$DCMP \
    ..
ninja install
ldc2 -version

cd ..
rm -rf build
if [[ $BOOTSTRAP ]]; then
    deactivate
fi

# If we don't do this a second time, we can end up linking to the wrong version of libphobos et al.
mkdir build
cd build
cmake -G Ninja \
    ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -DBUILD_SHARED_LIBS=BOTH \
    -DD_COMPILER=${PREFIX}/bin/ldmd2 \
    ..
ninja install
ldc2 -version
