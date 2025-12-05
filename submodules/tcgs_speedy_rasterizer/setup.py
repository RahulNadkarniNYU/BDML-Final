#
# Copyright (C) 2023, Inria
# GRAPHDECO research group, https://team.inria.fr/graphdeco
# All rights reserved.
#
# This software is free for non-commercial, research and evaluation use 
# under the terms of the LICENSE.md file.
#
# For inquiries contact  george.drettakis@inria.fr
#

from setuptools import setup
import os

base_dir = os.path.dirname(os.path.abspath(__file__))
tcgs_dir = os.path.join(base_dir, "cuda_rasterizer/tcgs")

# Function to find CUDA include directories
def find_cuda_include_dirs():
    """Find CUDA include directories."""
    cuda_include_dirs = []
    
    # Check CUDA_HOME environment variable
    cuda_home = os.environ.get('CUDA_HOME') or os.environ.get('CUDA_PATH')
    if cuda_home:
        cuda_include = os.path.join(cuda_home, 'include')
        if os.path.exists(cuda_include):
            cuda_include_dirs.append(cuda_include)
            return cuda_include_dirs  # Prefer explicit CUDA_HOME
    
    # Check conda/miniforge environment for CUDA
    conda_prefix = os.environ.get('CONDA_PREFIX')
    if conda_prefix:
        conda_include = os.path.join(conda_prefix, 'include')
        if os.path.exists(conda_include) and os.path.exists(os.path.join(conda_include, 'cuda_runtime.h')):
            cuda_include_dirs.append(conda_include)
            return cuda_include_dirs
        # Also check parent directory (for system-wide conda installations)
        parent_include = os.path.join(os.path.dirname(conda_prefix), 'include')
        if os.path.exists(parent_include) and os.path.exists(os.path.join(parent_include, 'cuda_runtime.h')):
            cuda_include_dirs.append(parent_include)
            return cuda_include_dirs
    
    # Try to find nvcc and infer CUDA path
    import shutil
    nvcc_path = shutil.which('nvcc')
    if nvcc_path:
        # nvcc is typically in bin/, so go up to find include/
        nvcc_dir = os.path.dirname(nvcc_path)
        if 'bin' in nvcc_dir:
            cuda_root = os.path.dirname(nvcc_dir)
            cuda_include = os.path.join(cuda_root, 'include')
            if os.path.exists(cuda_include):
                cuda_include_dirs.append(cuda_include)
                return cuda_include_dirs
    
    # Try common CUDA paths
    common_cuda_paths = [
        '/usr/local/cuda/include',
        '/usr/local/cuda-12/include',
        '/usr/local/cuda-11/include',
        '/opt/cuda/include',
        '/usr/include',
    ]
    
    for path in common_cuda_paths:
        if os.path.exists(path):
            cuda_include_dirs.append(path)
            break  # Only need one valid path
    
    return cuda_include_dirs

# Try to import torch - if not available, provide minimal setup for metadata extraction
try:
    from torch.utils.cpp_extension import CUDAExtension, BuildExtension
    
    # Get CUDA include directories
    cuda_include_dirs = find_cuda_include_dirs()
    
    # Build include directories list
    include_dirs = [
        os.path.join(base_dir, "cuda_rasterizer"),
        os.path.join(base_dir, "third_party/glm/"),
        tcgs_dir
    ]
    include_dirs.extend(cuda_include_dirs)
    
    ext_modules = [
        CUDAExtension(
            name="diff_gaussian_rasterization._C",
            sources=[
                "cuda_rasterizer/rasterizer_impl.cu",
                "cuda_rasterizer/forward.cu",
                "cuda_rasterizer/backward.cu",
                "cuda_rasterizer/tcgs/tcgs_forward.cu",
                "rasterize_points.cu",
                "ext.cpp"],
            include_dirs=include_dirs,
            extra_compile_args={
                "nvcc": [
                    "--expt-relaxed-constexpr",
                    "--ptxas-options=-v",
                    "-DTCGS_ENABLED=1",
                ],
                "cxx": ["-DTCGS_ENABLED=1"]
            }
        )
    ]
    cmdclass = {
        'build_ext': BuildExtension
    }
except ImportError:
    # torch not available during metadata extraction - will be available during build
    ext_modules = []
    cmdclass = {}

setup(
    name="diff_gaussian_rasterization",
    packages=['diff_gaussian_rasterization'],
    ext_modules=ext_modules,
    cmdclass=cmdclass
)
