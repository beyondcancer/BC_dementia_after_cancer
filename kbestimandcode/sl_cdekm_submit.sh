#!/bin/bash
#------------------------------------------------------------------------------
# sl_cdekm_submit.sh  -  submit the point run, the bootstrap array and the
#   combine step for one or more cancers. The point run and the array start
#   together; the combine step waits until both have finished successfully.
#
# Usage:  bash sl_cdekm_submit.sh bre pro lun col
#------------------------------------------------------------------------------
for CANCER in "$@"; do
	POINT=$(sbatch --parsable --job-name=cdekm_pt_${CANCER} sl_cdekm_point.sh ${CANCER})
	BLOCKS=$(sbatch --parsable --job-name=cdekm_bs_${CANCER} sl_cdekm_blocks.sh ${CANCER})
	COMBINE=$(sbatch --parsable --job-name=cdekm_cb_${CANCER} \
		--dependency=afterok:${POINT}:${BLOCKS} \
		--cpus-per-task=1 --time=01:00:00 --mem=8G \
		--output=slurm_cdekm_combine_${CANCER}_%j.out \
		--wrap="module load stata; stata-se -b do an_cdekm_combine.do ${CANCER}")
	echo "${CANCER}: point ${POINT}, blocks ${BLOCKS}, combine ${COMBINE}"
done
# Stata in batch mode may exit with status 0 even after an error, so afterok
# is not a guarantee: check an_cdekm_Combine_<cancer>.log, which lists the
# replicates found per block and warns about missing blocks. To rerun a block:
#   sbatch --array=<k> sl_cdekm_blocks.sh <cancer>
# then rerun the combine:  stata-se -b do an_cdekm_combine.do <cancer>
