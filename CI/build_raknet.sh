#!/usr/bin/env bash

if [ -z $1 ]; then
    echo "No build type provided to generator script! Failing!"
    exit 22
fi

BUILD_TYPE=$1 # No, this doesn't ever need to be quoted

git clone https://github.com/DreamWeave-MP/CrabNet extern/raknet

cd extern/raknet

cmake . -DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache

if [ $BUILD_TYPE == "Debug" ]; then
   cmake --build . --config Debug
else
    cmake --build . --config Release
fi

cd -
