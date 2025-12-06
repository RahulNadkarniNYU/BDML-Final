#!/bin/bash

# Enhanced Nsight Compute profiling script for TC-GS
# Profiles tensor core usage, memory bottlenecks, and kernel performance

OUTPUT_DIR="./profiling_results"
mkdir -p "$OUTPUT_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "=========================================="
echo "TC-GS Nsight Compute Profiling"
echo "=========================================="
echo ""

# Check if ncu is available
if ! command -v ncu &> /dev/null; then
    echo "Error: ncu (Nsight Compute) not found. Please install CUDA Toolkit."
    exit 1
fi

echo "Step 1/4: Running full kernel analysis..."
FULL_OUTPUT="$OUTPUT_DIR/ncu_full_${TIMESTAMP}.csv"
ncu \
    --set full \
    --kernel-regex "renderCUDA_TCGS|transform_coefs" \
    --kernel-name-base demangled \
    --csv \
    --target-processes all \
    --launch-skip 0 \
    --launch-count 10 \
    python train.py "$@" > "$FULL_OUTPUT" 2>&1

if [ $? -eq 0 ]; then
    echo "✓ Full report saved to: $FULL_OUTPUT"
else
    echo "✗ Full report generation failed. Check errors above."
fi
echo ""

echo "Step 2/4: Running focused metrics analysis..."
FOCUSED_OUTPUT="$OUTPUT_DIR/ncu_focused_${TIMESTAMP}.txt"

ncu \
    --section SpeedOfLight \
    --section MemoryWorkloadAnalysis \
    --section SchedulerStats \
    --section Occupancy \
    --section WarpStateStats \
    --section LaunchStats \
    --section ComputeWorkloadAnalysis \
    --section InstructionStats \
    --kernel-regex "renderCUDA_TCGS|transform_coefs" \
    --kernel-name-base demangled \
    --target-processes all \
    --launch-skip 0 \
    --launch-count 5 \
    python train.py "$@" > "$FOCUSED_OUTPUT" 2>&1

if [ $? -eq 0 ]; then
    echo "✓ Focused report saved to: $FOCUSED_OUTPUT"
else
    echo "✗ Focused report generation failed."
fi
echo ""

echo "Step 3/4: Running tensor core specific metrics..."
TENSOR_OUTPUT="$OUTPUT_DIR/ncu_tensor_${TIMESTAMP}.csv"

ncu \
    --metrics \
    sm__inst_executed_pipe_tensor.sum,\
    sm__pipe_tensor_cycles_active.avg.pct_of_peak_sustained.elapsed,\
    sm__pipe_tensor_cycles_active.avg.pct_of_peak_sustained.active,\
    sm__pipe_tensor_cycles_active.avg.peak_sustained.duration,\
    sm__inst_executed_pipe_tensor.sum.per_second,\
    sm__sass_thread_inst_executed_op_fp16_pred_on.sum,\
    sm__sass_thread_inst_executed_op_fp32_pred_on.sum,\
    sm__inst_executed.sum \
    --kernel-regex "renderCUDA_TCGS" \
    --kernel-name-base demangled \
    --csv \
    --target-processes all \
    --launch-skip 0 \
    --launch-count 10 \
    python train.py "$@" > "$TENSOR_OUTPUT" 2>&1

if [ $? -eq 0 ]; then
    echo "✓ Tensor core metrics saved to: $TENSOR_OUTPUT"
else
    echo "✗ Tensor core metrics generation failed."
fi
echo ""

echo "Step 4/4: Running bottleneck-specific metrics..."
BOTTLENECK_OUTPUT="$OUTPUT_DIR/ncu_bottlenecks_${TIMESTAMP}.csv"

ncu \
    --metrics \
    sm__warps_active.avg.pct_of_peak_sustained.active,\
    sm__warps_active.avg.pct_of_peak_sustained.elapsed,\
    smsp__warps_launched.sum,\
    sm__inst_executed_pipe_tensor.sum,\
    sm__pipe_tensor_cycles_active.avg.pct_of_peak_sustained.elapsed,\
    sm__pipe_tensor_cycles_active.avg.pct_of_peak_sustained.active,\
    l1tex__data_bank_conflicts_pipe_lsu_mem_shared_op_ld.sum,\
    l1tex__data_bank_conflicts_pipe_lsu_mem_shared_op_st.sum,\
    l1tex__t_bytes_pipe_lsu_mem_global_op_ld.sum,\
    l1tex__t_bytes_pipe_lsu_mem_global_op_st.sum,\
    dram__bytes_read.sum,\
    dram__bytes_write.sum,\
    sm__sass_thread_inst_executed_op_fp16_pred_on.sum,\
    sm__sass_thread_inst_executed_op_fp32_pred_on.sum,\
    sm__throughput.avg.pct_of_peak_sustained_elapsed,\
    sm__throughput.avg.pct_of_peak_sustained_active \
    --kernel-regex "renderCUDA_TCGS|transform_coefs" \
    --kernel-name-base demangled \
    --csv \
    --target-processes all \
    --launch-skip 0 \
    --launch-count 10 \
    python train.py "$@" > "$BOTTLENECK_OUTPUT" 2>&1

if [ $? -eq 0 ]; then
    echo "✓ Bottleneck metrics saved to: $BOTTLENECK_OUTPUT"
else
    echo "✗ Bottleneck metrics generation failed."
fi
echo ""

echo "=========================================="
echo "Profiling Complete!"
echo "=========================================="
echo ""
echo "Results saved in: $OUTPUT_DIR"
echo ""
echo "To view results:"
echo "  - Full report: cat $FULL_OUTPUT | less"
echo "  - Focused report: cat $FOCUSED_OUTPUT | less"
echo "  - Tensor core metrics: cat $TENSOR_OUTPUT | less"
echo "  - Bottleneck metrics: cat $BOTTLENECK_OUTPUT | less"
echo ""
echo "For interactive analysis, use:"
echo "  ncu-ui $FULL_OUTPUT"

