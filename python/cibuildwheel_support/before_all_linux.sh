#! /bin/bash

set -e
set -x

# Configure pip to use Acellera extra-index-url
mkdir -p $HOME/.config/pip
echo "[global]
extra-index-url = https://us-central1-python.pkg.dev/pypi-packages-455608/cpu/simple" > $HOME/.config/pip/pip.conf


# Configure pixi to use Acellera extra-index-url
mkdir -p $HOME/.pixi
echo "[pypi-config]
index-url = \"https://pypi.org/simple\"
extra-index-urls = [\"https://us-central1-python.pkg.dev/pypi-packages-455608/cpu/simple\"]
keyring-provider = \"subprocess\"" > $HOME/.pixi/config.toml

curl -fsSL https://pixi.sh/install.sh | sh
/root/.pixi/bin/pixi init .
/root/.pixi/bin/pixi add onnxruntime-cpp python=3.13
/root/.pixi/bin/pixi add --pypi onnxruntime openmm==8.2.1rc1

PIXIENV=$(pwd)/.pixi/envs/default


# ln -s ${PIXIENV}/lib/python3.13/site-packages/onnxruntime/capi/libonnxruntime.so.1.22.0 ${PIXIENV}/lib/python3.13/site-packages/onnxruntime/capi/libonnxruntime.so
cp ${PIXIENV}/lib/python3.13/site-packages/onnxruntime/capi/libonnxruntime.so.1.22.0 /usr/local/lib/libonnxruntime.so.1
ln -s /usr/local/lib/libonnxruntime.so.1 /usr/local/lib/libonnxruntime.so

# Configure build with Cmake
mkdir -p build
mkdir -p install
cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX=../install \
    -DCMAKE_PREFIX_PATH=${PIXIENV} \
    -DCMAKE_BUILD_TYPE=Release \
    -DOPENMM_DIR=${PIXIENV}/lib/python3.13/site-packages/openmm/
    

# Build OpenMMONNX
make -j4 install
make -j4 PythonInstall

cd ..


cp build/python/setup.py python/
cp build/python/openmmonnx.py python/openmmonnx/
cp build/python/OnnxPluginWrapper.cpp python/
cp -r install/include python/openmmonnx/

# Copy the libraries of openmm
mkdir -p python/openmm/
cp -r install/lib python/openmm/lib