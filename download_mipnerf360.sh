#!/bin/bash

# Download script for MipNeRF-360 dataset
# Based on: https://jonbarron.info/mipnerf360/

# Set your data directory (modify as needed)
DATA_DIR="${HOME}/data/mipnerf360"
mkdir -p "$DATA_DIR"
cd "$DATA_DIR"

echo "=========================================="
echo "MipNeRF-360 Dataset Download Script"
echo "=========================================="
echo ""
echo "Data will be downloaded to: $DATA_DIR"
echo ""

# Direct download link from Google Cloud Storage
DATASET_URL="https://storage.googleapis.com/gresearch/refraw360/360_extra_scenes.zip"
OUTPUT_FILE="360_extra_scenes.zip"

echo "Downloading MipNeRF-360 dataset..."
echo "URL: $DATASET_URL"
echo ""

# Download using wget
if command -v wget &> /dev/null; then
    echo "Using wget to download..."
    wget -c "$DATASET_URL" -O "$OUTPUT_FILE"
elif command -v curl &> /dev/null; then
    echo "Using curl to download..."
    curl -L -C - "$DATASET_URL" -o "$OUTPUT_FILE"
else
    echo "Error: Neither wget nor curl is available. Please install one of them."
    exit 1
fi

if [ $? -eq 0 ]; then
    echo ""
    echo "Download complete! Extracting..."
    
    # Extract the zip file
    if command -v unzip &> /dev/null; then
        unzip -q "$OUTPUT_FILE"
        echo "Extraction complete!"
    else
        echo "Error: unzip is not available. Please install unzip or extract manually."
        echo "You can extract with: unzip $OUTPUT_FILE"
        exit 1
    fi
    
    echo ""
    echo "=========================================="
    echo "Download and extraction complete!"
    echo "=========================================="
    echo ""
    echo "Dataset is located at: $DATA_DIR"
    echo ""
    echo "Available scenes:"
    ls -d */ 2>/dev/null | sed 's|/||' | sed 's/^/  - /'
    echo ""
    echo "Each scene should have:"
    echo "  scene_name/"
    echo "    ├── sparse/0/  (COLMAP reconstruction)"
    echo "    └── images/    (input images)"
    echo ""
    echo "You can now use this dataset for profiling:"
    echo "  cd /scratch/rn2592/BDML-Final"
    echo "  ./profile_quick.sh -s $DATA_DIR/<scene_name> -m <model_path>/<scene_name> --iteration 30000"
    echo ""
else
    echo ""
    echo "Error: Download failed. Please check your internet connection and try again."
    exit 1
fi

