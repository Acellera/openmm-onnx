#! /bin/bash

set -e
set -x

CHANNEL=cpu
ONNXPACKAGE=onnxruntime
EXTRAURLS=""
EXTRAURLS2=""
if [ "$ACCELERATOR" == "cu118" ]; then
    CHANNEL=cu118
    ONNXPACKAGE=onnxruntime-gpu
    EXTRAURLS="https://aiinfra.pkgs.visualstudio.com/PublicPackages/_packaging/onnxruntime-cuda-11/pypi/simple/"
    EXTRAURLS2=",\"https://aiinfra.pkgs.visualstudio.com/PublicPackages/_packaging/onnxruntime-cuda-11/pypi/simple/\""
elif [ "$ACCELERATOR" == "cu128" ]; then
    CHANNEL=cu128
    ONNXPACKAGE=onnxruntime-gpu
fi

# Configure pip to use Acellera extra-index-url
mkdir -p $HOME/.config/pip
echo "[global]
extra-index-url = https://us-central1-python.pkg.dev/pypi-packages-455608/${CHANNEL}/simple
${EXTRAURLS}" > $HOME/.config/pip/pip.conf


# Configure pixi to use Acellera extra-index-url
mkdir -p $HOME/.pixi
echo "[pypi-config]
index-url = \"https://pypi.org/simple\"
extra-index-urls = [\"https://us-central1-python.pkg.dev/pypi-packages-455608/${CHANNEL}/simple\"${EXTRAURLS2}]
keyring-provider = \"subprocess\"" > $HOME/.pixi/config.toml

PIXIENV=$(pwd)/.pixi/envs/default
PIXI=/root/.pixi/bin/pixi
curl -fsSL https://pixi.sh/install.sh | sh
$PIXI init .
$PIXI add onnxruntime-cpp python=3.13

if [ "$ACCELERATOR" == "cu118" ]; then
    # onnxruntime-gpu for 11.8 has issues finding numpy with a matching ABI but it exists in PyPI
    # so we need to use the unsafe-best-match strategy
    $PIXI add --pypi toml-cli
    $PIXIENV/bin/toml set --toml-path pixi.toml pypi-options.index-strategy "unsafe-best-match"
fi

$PIXI add -v --pypi openmm==8.2.1rc1 tensorrt $ONNXPACKAGE


# For CUDA 11 pip install onnxruntime-gpu --index-url https://aiinfra.pkgs.visualstudio.com/PublicPackages/_packaging/onnxruntime-cuda-11/pypi/simple/




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