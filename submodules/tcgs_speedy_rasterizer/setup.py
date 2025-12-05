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
    
    # Try to use PyTorch's CUDA detection first
    try:
        import torch
        if torch.cuda.is_available():
            # PyTorch might have CUDA paths in its build config
            # Check if we can get CUDA_HOME from torch
            torch_cuda_home = getattr(torch.utils.cpp_extension, 'CUDA_HOME', None)
            if torch_cuda_home:
                cuda_include = os.path.join(torch_cuda_home, 'include')
                if os.path.exists(cuda_include):
                    cuda_include_dirs.append(cuda_include)
                    print(f"Found CUDA include via PyTorch: {cuda_include}")
                    return cuda_include_dirs
    except:
        pass
    
    # Check CUDA_HOME environment variable
    cuda_home = os.environ.get('CUDA_HOME') or os.environ.get('CUDA_PATH')
    if cuda_home:
        cuda_include = os.path.join(cuda_home, 'include')
        if os.path.exists(cuda_include):
            cuda_include_dirs.append(cuda_include)
            print(f"Found CUDA include via CUDA_HOME: {cuda_include}")
            return cuda_include_dirs  # Prefer explicit CUDA_HOME
    
    # Check conda/miniforge environment for CUDA
    conda_prefix = os.environ.get('CONDA_PREFIX')
    if conda_prefix:
        # Check multiple possible locations in conda
        conda_paths = [
            os.path.join(conda_prefix, 'include'),
            os.path.join(os.path.dirname(conda_prefix), 'include'),  # Parent dir
            os.path.join(conda_prefix, 'pkgs', 'cuda-toolkit', 'include'),  # Conda cuda package
        ]
        for conda_include in conda_paths:
            if os.path.exists(conda_include):
                # Check if it has CUDA headers (either cuda_runtime.h or cuda directory)
                if (os.path.exists(os.path.join(conda_include, 'cuda_runtime.h')) or
                    os.path.exists(os.path.join(conda_include, 'cuda'))):
                    cuda_include_dirs.append(conda_include)
                    print(f"Found CUDA include in conda: {conda_include}")
                    return cuda_include_dirs
    
    # Try to find nvcc and infer CUDA path
    import shutil
    nvcc_path = shutil.which('nvcc')
    if nvcc_path:
        # nvcc is typically in bin/, so go up to find include/
        nvcc_dir = os.path.dirname(nvcc_path)
        # Check multiple possible locations relative to nvcc
        possible_roots = [nvcc_dir]  # Sometimes include is in same dir as bin
        if 'bin' in nvcc_dir:
            possible_roots.append(os.path.dirname(nvcc_dir))
        
        for cuda_root in possible_roots:
            cuda_include = os.path.join(cuda_root, 'include')
            if os.path.exists(cuda_include):
                # Verify it has CUDA headers
                if os.path.exists(os.path.join(cuda_include, 'cuda_runtime.h')) or os.path.exists(os.path.join(cuda_include, 'cuda')):
                    cuda_include_dirs.append(cuda_include)
                    print(f"Found CUDA include via nvcc: {cuda_include}")
                    return cuda_include_dirs
    
    # Try common CUDA paths (including miniforge/conda system paths)
    common_cuda_paths = [
        '/ext3/miniforge3/include',  # Based on nvcc location in error
        '/ext3/miniforge3/pkgs/cuda-toolkit/include',  # Conda cuda package location
        '/usr/local/cuda/include',
        '/usr/local/cuda-12/include',
        '/usr/local/cuda-11/include',
        '/opt/cuda/include',
        '/usr/include',
    ]
    
    for path in common_cuda_paths:
        if os.path.exists(path):
            # Verify it has CUDA headers
            if os.path.exists(os.path.join(path, 'cuda_runtime.h')) or os.path.exists(os.path.join(path, 'cuda')):
                cuda_include_dirs.append(path)
                print(f"Found CUDA include in common path: {path}")
                break  # Only need one valid path
    
    if not cuda_include_dirs:
        print("WARNING: Could not find CUDA include directories automatically!")
        print("Please set CUDA_HOME environment variable to your CUDA installation path.")
    
    return cuda_include_dirs

# Try to import torch - if not available, provide minimal setup for metadata extraction
try:
    from torch.utils.cpp_extension import CUDAExtension, BuildExtension
    import torch
    
    # Get CUDA include directories (fallback if PyTorch doesn't find them automatically)
    cuda_include_dirs = find_cuda_include_dirs()
    
    # Build include directories list - PyTorch's CUDAExtension will automatically
    # add CUDA paths, but we add our custom paths and any found CUDA paths
    include_dirs = [
        os.path.join(base_dir, "cuda_rasterizer"),
        os.path.join(base_dir, "third_party/glm/"),
        tcgs_dir
    ]
    
    # Only add CUDA include dirs if we found them and they're not already in PyTorch's paths
    # PyTorch should handle CUDA paths automatically, but in some environments it might not
    if cuda_include_dirs:
        include_dirs.extend(cuda_include_dirs)
        print(f"Adding CUDA include directories: {cuda_include_dirs}")
    else:
        print("Note: Relying on PyTorch's automatic CUDA path detection")
    
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
