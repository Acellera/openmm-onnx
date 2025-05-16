#! /bin/bash

set -e
set -x


curl -fsSL https://pixi.sh/install.sh | sh
/root/.pixi/bin/pixi init .
/root/.pixi/bin/pixi add onnxruntime-cpp gcc_linux-64=9 gxx_linux-64=9 python=3.13 openmm

PIXIENV=$(pwd)/.pixi/envs/default


# Configure build with Cmake
mkdir -p build
mkdir -p install
cd build

cmake .. \
    -DCMAKE_CXX_COMPILER=${PIXIENV}/bin/x86_64-conda-linux-gnu-g++ \
    -DCMAKE_C_COMPILER=${PIXIENV}/bin/x86_64-conda-linux-gnu-gcc \
    -DCMAKE_INSTALL_PREFIX=../install \
    -DCMAKE_PREFIX_PATH=${PIXIENV} \
    -DCMAKE_BUILD_TYPE=Release \
    -DOPENMM_DIR=${PIXIENV}

# Build OpenMMONNX
make -j4 install
make -j4 PythonInstall

cd ..


cp build/python/setup.py python/
cp build/python/openmmonnx.py python/openmmonnx/
cp build/python/OnnxPluginWrapper.cpp python/openmmonnx/
cp -r install/include python/openmmonnx/

# Copy the libraries of openmm
mkdir -p python/openmm/
cp -r install/lib python/openmm/lib