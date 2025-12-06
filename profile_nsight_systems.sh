#!/bin/bash

# Enhanced Nsight Systems profiling script for TC-GS
# Provides timeline view of kernel execution, memory transfers, and system activity

OUTPUT_DIR="./profiling_results"
mkdir -p "$OUTPUT_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="$OUTPUT_DIR/tcgs_profile_${TIMESTAMP}.nsys-rep"

echo "=========================================="
echo "TC-GS Nsight Systems Profiling"
echo "=========================================="
echo ""

# Check if nsys is available
if ! command -v nsys &> /dev/null; then
    echo "Error: nsys (Nsight Systems) not found. Please install CUDA Toolkit."
    exit 1
fi

echo "Starting Nsight Systems profiling..."
echo "Output will be saved to: $OUTPUT_FILE"
echo ""
echo "This will trace:"
echo "  - CUDA kernel launches and execution"
echo "  - Memory transfers (H2D, D2H, D2D)"
echo "  - NVTX markers (if available)"
echo "  - OS runtime activity"
echo ""

# Profile with comprehensive tracing
nsys profile \
    --trace=cuda,nvtx,osrt \
    --cuda-memory-verbose=true \
    --cuda-um-cpu-page-faults=true \
    --cuda-um-gpu-page-faults=true \
    --gpu-metrics-device=all \
    --output="$OUTPUT_FILE" \
    --force-overwrite=true \
    --stop-on-exit=true \
    --capture-range=cudaProfilerApi \
    python train.py "$@"

PROFILE_EXIT_CODE=$?

echo ""
if [ $PROFILE_EXIT_CODE -eq 0 ]; then
    echo "=========================================="
    echo "Profiling Complete!"
    echo "=========================================="
    echo ""
    echo "Report saved to: $OUTPUT_FILE"
    echo ""
    echo "To view the report:"
    echo "  Interactive GUI: nsys-ui $OUTPUT_FILE"
    echo ""
    echo "To generate statistics:"
    echo "  GPU trace stats: nsys stats --report gputrace $OUTPUT_FILE"
    echo "  CUDA API stats: nsys stats --report cudaapisum $OUTPUT_FILE"
    echo "  Kernel stats: nsys stats --report cudaapisum --force-overwrite true $OUTPUT_FILE > ${OUTPUT_FILE%.nsys-rep}_stats.txt"
    echo ""
    
    # Generate quick stats
    echo "Generating quick statistics..."
    nsys stats --report gputrace --force-overwrite true "$OUTPUT_FILE" > "${OUTPUT_FILE%.nsys-rep}_gputrace.txt" 2>&1
    if [ $? -eq 0 ]; then
        echo "✓ GPU trace stats saved to: ${OUTPUT_FILE%.nsys-rep}_gputrace.txt"
    fi
else
    echo "✗ Profiling failed with exit code: $PROFILE_EXIT_CODE"
    echo "Check the error messages above for details."
fi

