#!/bin/bash

OUTPUT_DIR="./profiling_results"
mkdir -p "$OUTPUT_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="$OUTPUT_DIR/tcgs_profile_${TIMESTAMP}.nsys-rep"

echo "Starting Nsight Systems profiling..."
echo "Output will be saved to: $OUTPUT_FILE"
echo ""

nsys profile \
    --trace=cuda,nvtx,osrt \
    --cuda-memory-verbose=true \
    --output="$OUTPUT_FILE" \
    --force-overwrite=true \
    --stop-on-exit=true \
    python render.py "$@"

echo ""
echo "Profiling complete!"
echo "Open the report with: nsys-ui $OUTPUT_FILE"
echo "Or use: nsys stats --report gputrace $OUTPUT_FILE"

