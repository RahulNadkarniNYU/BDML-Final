#!/bin/bash

#SBATCH --job-name=bdml_final
#SBATCH --account=csci_ga_3033-2025fa
#SBATCH --partition=n1s8-t4-1
#SBATCH --open-mode=append
#SBATCH --output=./%j_%x.out
#SBATCH --error=./%j_%x.err
#SBATCH --export=ALL
#SBATCH --time=04:00:00
#SBATCH --gres=gpu:1
#SBATCH --requeue

# Set your paths here
NETID="rn2592"
DATA_PATH="/scratch/${NETID}/data/mipnerf360"  # Path to your dataset
SCENE="flowers"  # Scene name (flowers, treehill, room, etc.)
MODEL_PATH="/scratch/${NETID}/BDML-Final/output/${SCENE}"  # Where to save checkpoints

singularity exec --bind /scratch --nv \
    --overlay /scratch/${NETID}/overlay-25GB-500K.ext3:ro \
    /scratch/${NETID}/cuda12.8.1-cudnn9.8.0-ubuntu24.04.2.sif \
    /bin/bash -c "
source /ext3/env.sh
conda activate bdml_env

cd /scratch/${NETID}/BDML-Final

# Run training with required arguments
python train.py \
    -s ${DATA_PATH}/${SCENE}/ \
    -m ${MODEL_PATH} \
    --iterations 30000 \
    --test_iterations 7000 30000 \
    --save_iterations 7000 30000 \
    --quiet \
    --disable_viewer
"

