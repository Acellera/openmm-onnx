from setuptools import setup, Extension
import os
import platform

openmm_dir = '@OPENMM_DIR@'
openmmonnx_header_dir = '@OPENMMONNX_HEADER_DIR@'
openmmonnx_library_dir = '@OPENMMONNX_LIBRARY_DIR@'

# setup extra compile and link arguments on Mac
extra_compile_args=['-std=c++11', '-D_GLIBCXX_USE_CXX11_ABI=1']
extra_link_args = []
runtime_library_dirs = ["$ORIGIN/../openmm/lib"]

if platform.system() == 'Darwin':
    extra_compile_args += ['-stdlib=libc++', '-mmacosx-version-min=10.13']
    extra_link_args += ['-stdlib=libc++', '-mmacosx-version-min=10.13', '-Wl']
    runtime_library_dirs = ['@loader_path/../openmm/lib']

extension = Extension(name='openmmonnx._openmmonnx',
                      sources=['OnnxPluginWrapper.cpp'],
                      libraries=['OpenMM', 'OpenMMONNX'],
                      include_dirs=[os.path.join(openmm_dir, 'include'), openmmonnx_header_dir],
                      library_dirs=[os.path.join(openmm_dir, 'lib'), openmmonnx_library_dir],
                      runtime_library_dirs=runtime_library_dirs,
                      extra_compile_args=extra_compile_args,
                      extra_link_args=extra_link_args
                     )

setup(name='OpenMMONNX',
      version='0.1',
      py_modules=['openmmonnx'],
      ext_modules=[extension],
      install_requires=['openmm==8.2.1rc1']
     )
