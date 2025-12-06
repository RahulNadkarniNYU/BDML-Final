#!/bin/bash

# Quick script to check if dataset is properly extracted

echo "Checking dataset structure..."
echo ""

# Check current directory
CURRENT_DIR=$(pwd)
echo "Current directory: $CURRENT_DIR"
echo ""

# Check if zip file exists
if [ -f "360_extra_scenes.zip" ]; then
    echo "✓ Found 360_extra_scenes.zip"
    echo "  You need to unzip this file!"
    echo ""
fi

# Check for scene directories
SCENES=("flowers" "treehill" "bicycle" "garden" "stump" "room" "counter" "kitchen" "bonsai")

for scene in "${SCENES[@]}"; do
    if [ -d "$scene" ]; then
        echo "✓ Found scene: $scene"
        
        # Check if it has the required structure
        if [ -d "$scene/sparse" ] && [ -d "$scene/images" ]; then
            echo "  ✓ Has sparse/ and images/ directories (GOOD!)"
        else
            echo "  ⚠ Missing sparse/ or images/ directories"
        fi
    fi
done

echo ""
echo "If you see scene directories with sparse/ and images/, you're ready!"
echo "If you only see the zip file, run: unzip 360_extra_scenes.zip"


