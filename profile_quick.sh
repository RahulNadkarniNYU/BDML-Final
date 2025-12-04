#!/bin/bash

echo "=== Profiling Suite ==="
echo ""

echo "1. Running Nsight Systems (timeline profiling)..."
./profile_nsight_systems.sh "$@"

echo ""
echo "2. Running Nsight Compute (kernel analysis)..."
./profile_nsight_compute.sh "$@"

echo ""
echo "=== Profiling Complete ==="
echo "Check ./profiling_results/ for all output files"

