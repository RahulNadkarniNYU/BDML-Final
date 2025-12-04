#!/bin/bash


OUTPUT_DIR="./profiling_results"
mkdir -p "$OUTPUT_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "Starting Nsight Compute profiling..."
echo "This will profile the renderCUDA_TCGS kernel in detail"
echo ""

echo "Running full kernel analysis..."
FULL_OUTPUT="$OUTPUT_DIR/ncu_full_${TIMESTAMP}.csv"
ncu \
    --set full \
    --kernel-regex "renderCUDA_TCGS|transform_coefs" \
    --kernel-name-base demangled \
    --csv \
    --target-processes all \
    python render.py "$@" > "$FULL_OUTPUT" 2>&1

echo "Full report saved to: $FULL_OUTPUT"
echo ""

echo "Running focused metrics analysis..."
FOCUSED_OUTPUT="$OUTPUT_DIR/ncu_focused_${TIMESTAMP}.txt"

ncu \
    --section SpeedOfLight \
    --section MemoryWorkloadAnalysis \
    --section SchedulerStats \
    --section Occupancy \
    --section WarpStateStats \
    --section LaunchStats \
    --kernel-regex "renderCUDA_TCGS" \
    --kernel-name-base demangled \
    --target-processes all \
    python render.py "$@" > "$FOCUSED_OUTPUT" 2>&1

echo "Focused report saved to: $FOCUSED_OUTPUT"
echo ""

echo "Running bottleneck-specific metrics..."
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
    dram__bytes_read.sum,\
    dram__bytes_write.sum,\
    l1tex__t_bytes_pipe_lsu_mem_global_op_ld.sum,\
    sm__sass_thread_inst_executed_op_fp16_pred_on.sum,\
    sm__sass_thread_inst_executed_op_fp32_pred_on.sum \
    --kernel-regex "renderCUDA_TCGS" \
    --kernel-name-base demangled \
    --csv \
    --target-processes all \
    python render.py "$@" > "$BOTTLENECK_OUTPUT" 2>&1

echo "Bottleneck metrics saved to: $BOTTLENECK_OUTPUT"
echo ""
echo "Profiling complete!"
echo ""
echo "To view results:"
echo "  - Full report: cat $FULL_OUTPUT"
echo "  - Focused report: cat $FOCUSED_OUTPUT"
echo "  - Bottleneck metrics: cat $BOTTLENECK_OUTPUT"

