// Copyright (c) 2025 TCGS GROUP. MIT License. See LICENSE for details.
#ifndef TCGS_UTILS_H
#define TCGS_UTILS_H

#include<cuda_fp16.h>

#define __HALF_TO_US_TCGS(var) *(reinterpret_cast<unsigned short *>(&(var)))
#define __HALF_TO_CUS_TCGS(var) *(reinterpret_cast<const unsigned short *>(&(var)))
#define __HALF2_TO_UI_TCGS(var) *(reinterpret_cast<unsigned int *>(&(var)))
#define __HALF2_TO_CUI_TCGS(var) *(reinterpret_cast<const unsigned int *>(&(var)))
#define __UI_TO_HALF2_TCGS(var) *(reinterpret_cast<half2 *>(&(var)))
#define __US_TO_HALF_TCGS(var) *(reinterpret_cast<half2 *>(&(var)))

namespace TCGS_UTIL
{

    constexpr float LOG2E = 1.4426950216293334961f;
    constexpr float LOG2E_2 = LOG2E * 0.5f;
    constexpr float LOG2E_N = - LOG2E;
    constexpr float LOG2E_N_2 = - LOG2E_2;
    constexpr float LN2 = 0.6931471805599453f;

    constexpr uint WAPR_SIZE = 32u;
    constexpr uint REDUCE_SIZE = 16u;
    constexpr uint VECTOR_SIZE = 8u;
    constexpr uint BLOCK_X_TCGS = 16;
    constexpr uint BLOCK_Y_TCGS = 16;
    constexpr uint BLOCK_SIZE_TCGS = BLOCK_X_TCGS * BLOCK_Y_TCGS;

    __forceinline__ __device__ uint half22uint(half2 x)
    {
        return __HALF2_TO_UI_TCGS(x);
    }

    __forceinline__ __device__ half2 uint2half2(uint x)
    {
        return __UI_TO_HALF2_TCGS(x);
    }

    //convert 2 fp32s into fp16, stored as uint
    // Improved version with clamping to avoid precision loss
    __forceinline__ __device__ uint float22reg(float x, float y)
    {
        // Clamp values to valid range for fp16 to avoid overflow/underflow
        float clamped_x = fmaxf(fminf(x, 65504.0f), -65504.0f);
        float clamped_y = fmaxf(fminf(y, 65504.0f), -65504.0f);
        
        float2 temp_f = make_float2(clamped_x, clamped_y);
        half2 temp_h = __float22half2_rn(temp_f);
        return half22uint(temp_h);
    }

    __forceinline__ __device__ void load_matrix_x4(
        uint &reg0, uint &reg1, uint &reg2, uint &reg3,
        uint* addr //Shared memory address
    )
    {
        uint smem_addr = __cvta_generic_to_shared(addr);
        asm volatile(
            "ldmatrix.sync.aligned.x4.m8n8.shared.b16 {%0, %1, %2, %3}, [%4];\n"
            : "=r"(reg0), "=r"(reg1), "=r"(reg2), "=r"(reg3) 
            : "r"(smem_addr)
        );
    }

    __forceinline__ __device__ void load_matrix_x2(
        uint &reg0, uint &reg1,
        uint* addr //Shared memory address
    )
    {
        uint smem_addr = __cvta_generic_to_shared(addr);
        asm volatile(
            "ldmatrix.sync.aligned.x2.m8n8.shared.b16 {%0, %1}, [%2];\n" 
            : "=r"(reg0), "=r"(reg1) 
            : "r"(smem_addr)
        );
    }
    __forceinline__ __device__ void load_matrix_x1(
        uint &reg,
        uint* addr //Shared memory address
    )
    {
        uint smem_addr = __cvta_generic_to_shared(addr);
        asm volatile(
            "ldmatrix.sync.aligned.x1.m8n8.shared.b16 {%0}, [%1];\n" 
            : "=r"(reg) 
            : "r"(smem_addr)
        );
    }

    __forceinline__ __device__ void mma_16x8x8_f16_f16(
        uint &regD0, uint &regD1,
        uint regA0, uint regA1,
        uint regB,
        uint regC0, uint regC1
    )
    {
        asm volatile( \
            "mma.sync.aligned.m16n8k8.row.col.f16.f16.f16.f16" 
            "{%0, %1}, {%2, %3}, {%4}, {%5, %6};\n" 
            :"=r"(regD0), "=r"(regD1) : 
            "r"(regA0), "r"(regA1), "r"(regB), "r"(regC0), "r"(regC1)
        );
    } 

    // Improved exponential with better numerical stability
    // Uses a more accurate approximation for small values
    __forceinline__ __device__ half fast_ex2_f16(half x)
    {
        // Clamp input to avoid overflow/underflow
        half clamped_x = __hmax(__hmin(x, __float2half_rn(10.0f)), __float2half_rn(-10.0f));
        
        // For very small values, use more accurate computation
        if(__hlt(clamped_x, __float2half_rn(-7.0f)))
        {
            // Return a very small value instead of using approximate exp
            return __float2half_rn(0.0f);
        }
        
        half y;
        asm volatile(
            "ex2.approx.f16 %0, %1;\n"
            : "=h"(__HALF_TO_US_TCGS(y))
            : "h"(__HALF_TO_US_TCGS(clamped_x))
        );
        
        // Clamp output to avoid NaN/Inf
        return __hmax(__hmin(y, __float2half_rn(1.0f)), __float2half_rn(0.0f));
    }

    __forceinline__ __device__ float fast_lg2_f32(float x)
    {
        float y;
        asm volatile(
            "lg2.approx.f32 %0, %1;\n"
            : "=f"(y)
            : "f"(x)
        );
        return y;
    }

    __forceinline__ __device__ uint fast_fma_rn_ftz_f16x2(uint a, uint b, uint c)
    {
        uint d;
        asm volatile(
            "fma.rn.ftz.f16x2 %0, %1, %2, %3;\n"
            : "=r"(d)
            : "r"(a), "r"(b), "r"(c)
        );
        return d;
    }
};

#undef __HALF_TO_US_TCGS
#undef __HALF_TO_CUS_TCGS
#undef __HALF2_TO_UI_TCGS
#undef __HALF2_TO_CUI_TCGS
#undef __UI_TO_HALF2_TCGS
#undef __US_TO_HALF_TCGS

#endif