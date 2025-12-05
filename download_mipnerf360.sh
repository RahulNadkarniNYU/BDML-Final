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

# Method 1: Using gdown (for Google Drive)
# The MipNeRF-360 dataset is on Google Drive, so we need gdown
if ! command -v gdown &> /dev/null; then
    echo "Installing gdown for Google Drive downloads..."
    pip install gdown
fi

echo "Downloading MipNeRF-360 dataset from Google Drive..."
echo ""
echo "Note: You need to get the Google Drive file IDs from:"
echo "  https://jonbarron.info/mipnerf360/"
echo ""
echo "The dataset is split into two parts. To download:"
echo ""
echo "1. Visit https://jonbarron.info/mipnerf360/"
echo "2. Click 'Dataset Pt. 1' - copy the Google Drive file ID from the URL"
echo "3. Click 'Dataset Pt. 2' - copy the Google Drive file ID from the URL"
echo ""
echo "Then run:"
echo "  gdown --id <PART1_FILE_ID> -O mipnerf360_part1.tar.gz"
echo "  gdown --id <PART2_FILE_ID> -O mipnerf360_part2.tar.gz"
echo ""
echo "Or if you have direct download URLs (after getting download permission):"
echo "  wget --no-check-certificate 'https://drive.google.com/uc?export=download&id=<FILE_ID>' -O mipnerf360_part1.tar.gz"
echo ""

# Method 2: Direct wget (if you have the download URLs)
# Uncomment and fill in the URLs if you have them:
# echo "Downloading Part 1..."
# wget -c "https://drive.google.com/uc?export=download&id=<FILE_ID_1>" -O mipnerf360_part1.tar.gz
# 
# echo "Downloading Part 2..."
# wget -c "https://drive.google.com/uc?export=download&id=<FILE_ID_2>" -O mipnerf360_part2.tar.gz
# 
# echo "Extracting..."
# tar -xzf mipnerf360_part1.tar.gz
# tar -xzf mipnerf360_part2.tar.gz

# Quick download for a single scene (if available)
echo "=========================================="
echo "Quick Download Option: Single Scene"
echo "=========================================="
echo ""
echo "If you only need one scene for testing/profiling, you can download"
echo "individual scenes. Common scenes:"
echo "  - room (indoor, small)"
echo "  - bicycle (outdoor)"
echo "  - garden (outdoor)"
echo ""
echo "Check the MipNeRF-360 website for individual scene download links."
echo ""

echo "After downloading, extract with:"
echo "  tar -xzf mipnerf360_part1.tar.gz"
echo "  tar -xzf mipnerf360_part2.tar.gz"
echo ""
echo "Your directory structure should be:"
echo "  $DATA_DIR/"
echo "    ├── bicycle/"
echo "    │   ├── sparse/0/"
echo "    │   └── images/"
echo "    ├── room/"
echo "    └── ... (other scenes)"
echo ""

