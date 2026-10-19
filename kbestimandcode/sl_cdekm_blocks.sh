#!/bin/bash
#------------------------------------------------------------------------------
# sl_cdekm_blocks.sh  -  bootstrap blocks of an_cdekm.do for one cancer
#   Array task k runs block k: replicates (k-1)*50+1 to k*50
#   (block size: cde_reps_per_block in inc_cde_settings.do)
#
# Usage:  sbatch sl_cdekm_blocks.sh bre
#         sbatch --array=7 sl_cdekm_blocks.sh bre     (rerun one block)
#
# Run from the folder holding an_cdekm.do, pr_cde_programs.do and
# inc_cde_settings.do (outputs are written there).
# Time: ~50 replicates plus one point-estimate fit and the data preparation.
# Adjust --time, --mem and the module line for your cluster.
#------------------------------------------------------------------------------
#SBATCH --job-name=cdekm_blocks
#SBATCH --array=1-20
#SBATCH --cpus-per-task=1
#SBATCH --time=36:00:00
#SBATCH --mem=16G
#SBATCH --output=slurm_cdekm_blocks_%x_%A_%a.out
#SBATCH --exclude=c36,c37

CANCER=$1
if [ -z "$CANCER" ]; then echo "Give the cancer type, e.g. sbatch sl_cdekm_blocks.sh bre"; exit 1; fi

module load stata          # or whatever your cluster uses

# an_cdekm.do reads the block number from SLURM_ARRAY_TASK_ID.
# Note: stata-se -b writes its own batch log an_cdekm.log, which concurrent
# tasks overwrite; ignore it. Each block has its own log, an_cdekm_<cancer>_b<k>.log
stata-se -b do an_cdekm.do ${CANCER}
