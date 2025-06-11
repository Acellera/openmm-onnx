import os
import ctypes
import site
import platform

SP_DIR = site.getsitepackages()[0]

# Since onnxruntime needs a lot of NVIDIA libraries but doesn't set the right RPATH for the equivalent
# nvidia PyPI packages, we need to preload them here so they can be found when importing onnxruntime
libprefix = "lib"
libext = "so"
if platform.system() == "Darwin":
    libext = "dylib"
if platform.system() == "Windows":
    libprefix = ""
    libext = "dll"

libpaths = [
    os.path.join(SP_DIR, "nvidia", "cublas", "lib", f"{libprefix}cublas.{libext}.12"),
    os.path.join(SP_DIR, "tensorrt_libs", f"{libprefix}nvinfer.{libext}.10"),
    os.path.join(SP_DIR, "tensorrt_libs", f"{libprefix}nvinfer_plugin.{libext}.10"),
    os.path.join(SP_DIR, "tensorrt_libs", f"{libprefix}nvonnxparser.{libext}.10"),
    os.path.join(
        SP_DIR, "nvidia", "cuda_runtime", "lib", f"{libprefix}cudart.{libext}.12"
    ),
    os.path.join(SP_DIR, "nvidia", "cudnn", "lib", f"{libprefix}cudnn.{libext}.9"),
    os.path.join(SP_DIR, "nvidia", "curand", "lib", f"{libprefix}curand.{libext}.10"),
    os.path.join(SP_DIR, "nvidia", "cufft", "lib", f"{libprefix}cufft.{libext}.11"),
    os.path.join(
        SP_DIR, "nvidia", "cuda_nvrtc", "lib", f"{libprefix}nvrtc.{libext}.12"
    ),
]
for lib in libpaths:
    ctypes.CDLL(lib, mode=ctypes.RTLD_GLOBAL)

ctypes.CDLL(
    os.path.join(SP_DIR, "onnxruntime", "capi", "libonnxruntime.so.1.22.0"),
    mode=ctypes.RTLD_GLOBAL,
)

from .openmmonnx import *
