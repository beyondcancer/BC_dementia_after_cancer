#!/bin/bash
#------------------------------------------------------------------------------
# sl_cdekm_point.sh  -  point run of an_cdekm.do for one cancer
#   (point estimates, curves, balance; no bootstrap)
#
# Usage:  sbatch sl_cdekm_point.sh bre
#
# Run from the folder holding an_cdekm.do, pr_cde_programs.do and
# inc_cde_settings.do (outputs are written there).
# Adjust --time, --mem and the module line for your cluster.
#------------------------------------------------------------------------------
#SBATCH --job-name=cdekm_point
#SBATCH --cpus-per-task=1
#SBATCH --time=24:00:00
#SBATCH --mem=64G
#SBATCH --output=slurm_cdekm_point_%x_%j.out
#SBATCH --exclude=c37

CANCER=$1
if [ -z "$CANCER" ]; then echo "Give the cancer type, e.g. sbatch sl_cdekm_point.sh bre"; exit 1; fi

module load stata          # or whatever your cluster uses

# Make sure no array task id is inherited, so this is a point run
unset SLURM_ARRAY_TASK_ID

stata-se -b do an_cdekm.do ${CANCER}
