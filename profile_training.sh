#!/bin/bash

# Profile training script specifically for TC-GS
# This script profiles the training loop to identify bottlenecks

OUTPUT_DIR="./profiling_results"
mkdir -p "$OUTPUT_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "=========================================="
echo "TC-GS Training Profiling"
echo "=========================================="
echo ""

# Check for required tools
if ! command -v nsys &> /dev/null; then
    echo "Error: nsys (Nsight Systems) not found."
    exit 1
fi

if ! command -v ncu &> /dev/null; then
    echo "Error: ncu (Nsight Compute) not found."
    exit 1
fi

# Parse arguments
TRAIN_ITERATIONS=100
SCENE=""
DATA_PATH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --iterations)
            TRAIN_ITERATIONS="$2"
            shift 2
            ;;
        --scene)
            SCENE="$2"
            shift 2
            ;;
        --data)
            DATA_PATH="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--iterations N] [--scene SCENE] [--data DATA_PATH]"
            exit 1
            ;;
    esac
done

echo "Profiling configuration:"
echo "  Training iterations: $TRAIN_ITERATIONS"
echo "  Scene: ${SCENE:-default}"
echo ""

# Build training command
TRAIN_CMD="python train.py"
if [ -n "$SCENE" ] && [ -n "$DATA_PATH" ]; then
    TRAIN_CMD="$TRAIN_CMD -s $DATA_PATH/$SCENE"
fi
TRAIN_CMD="$TRAIN_CMD --iterations $TRAIN_ITERATIONS"

echo "Training command: $TRAIN_CMD"
echo ""

# Step 1: Systems-level profiling
echo "Step 1/2: Running Nsight Systems profiling..."
SYS_OUTPUT="$OUTPUT_DIR/training_systems_${TIMESTAMP}.nsys-rep"
nsys profile \
    --trace=cuda,nvtx,osrt \
    --cuda-memory-verbose=true \
    --output="$SYS_OUTPUT" \
    --force-overwrite=true \
    --stop-on-exit=true \
    $TRAIN_CMD

if [ $? -eq 0 ]; then
    echo "✓ Systems profile saved to: $SYS_OUTPUT"
    nsys stats --report gputrace --force-overwrite true "$SYS_OUTPUT" > "${SYS_OUTPUT%.nsys-rep}_stats.txt" 2>&1
else
    echo "✗ Systems profiling failed."
fi
echo ""

# Step 2: Compute-level profiling (sample a few iterations)
echo "Step 2/2: Running Nsight Compute profiling (sampling first 10 iterations)..."
COMPUTE_OUTPUT="$OUTPUT_DIR/training_compute_${TIMESTAMP}.csv"
ncu \
    --set full \
    --kernel-regex "renderCUDA_TCGS|transform_coefs" \
    --kernel-name-base demangled \
    --csv \
    --target-processes all \
    --launch-skip 0 \
    --launch-count 10 \
    $TRAIN_CMD > "$COMPUTE_OUTPUT" 2>&1

if [ $? -eq 0 ]; then
    echo "✓ Compute profile saved to: $COMPUTE_OUTPUT"
else
    echo "✗ Compute profiling failed."
fi
echo ""

echo "=========================================="
echo "Training Profiling Complete!"
echo "=========================================="
echo ""
echo "Results:"
echo "  - Systems profile: $SYS_OUTPUT"
echo "  - Compute profile: $COMPUTE_OUTPUT"
echo ""
echo "View with:"
echo "  nsys-ui $SYS_OUTPUT"

