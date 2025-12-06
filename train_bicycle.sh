#!/bin/bash

# Training script for bicycle dataset
# Your bicycle directory should have: sparse/, images/, images_2/, images_4/, images_8/

# Path to your bicycle dataset directory (update this to your actual path)
BICYCLE_DIR="path/to/your/bicycle"

# Path where you want to save the trained model
OUTPUT_DIR="./output/bicycle"

# Choose which image resolution to use:
# "images" (full res), "images_2" (50%), "images_4" (25%), "images_8" (12.5%)
IMAGE_FOLDER="images"

# Optional: specify GPU device
# export CUDA_VISIBLE_DEVICES=0

# Run training
python train.py \
    -s ${BICYCLE_DIR} \
    -m ${OUTPUT_DIR} \
    -i ${IMAGE_FOLDER}

