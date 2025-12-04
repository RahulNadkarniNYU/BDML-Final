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

# Try to import torch - if not available, provide minimal setup for metadata extraction
try:
    from torch.utils.cpp_extension import CUDAExtension, BuildExtension
    
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
            include_dirs=[
                os.path.join(base_dir, "cuda_rasterizer"),
                os.path.join(base_dir, "third_party/glm/"),
                tcgs_dir
            ],
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
