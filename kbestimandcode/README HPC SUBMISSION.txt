
*Data setup
data files in main project folder (e.g. <root>/dementia)
create two subfolders of this for (i) larger cancers (top 10) and (ii) smaller
in each, copy all the dofiles from kbestimandcode, and also a copy of inc_excludepriorandset_dementia.do

*KM run for one or more cancers (up to all 20)
a) set number of blocks and blocksize in inc_cde_settings (e.g. 25 x 20 reps for larger cancers or 10 x 50 reps for smaller ones (nb this will be different in the two folders)
aii) set the array number in the blocks script appropriately (i.e. to 10 for smaller cancers; 20 for bigger).
b) check other settings incl relative location of data files, include files, confounder/adjustment lists and model parameters
c) from each of the 2 subfolders in turn, submit in putty with: bash sl_cdekm_submit.sh <list of ten cancers - largerst 10 or smallest 10 depending on folder>)

NB this will call the blocks and point submission scripts immediately, and the combine one after completion

After everything is finished, can run an_processout_tidyandcombineHPCresults (pull all the files off the server to a tempfile, copy the tidying do-file to the same folder and run it - then tidied results can be copied to $results_an_dem/hpc_output/results (stata dataset files) and logfiles to /logs on the same path.

other useful hpc/putty commands:

see queue (formatted)
squeue -u encdkbha -o "%.12i %.20j %.6N %.10M %.8T"

check pending jobs:
squeue -u $USER -t PENDING -o "%.18i %.20j %.10m %.12l %.25r"

cancel jobs/specific sub jobs, e.g.
scancel "7244241_[2-5]" "7244235_[1-2]" 7244183_2 "7244229_[1-3]" "7244226_[2-10]"
scancel 7244183

resubmit a specific bootstrap run e.g. 
sbatch --exclude=c36,c37 --mem=24G --time=36:00:00 --job-name=cdekm_bs_nhl --array=2 sl_cdekm_blocks.sh nhl
[for this, cancel the related combine first and submit it separately after all blocks are done, with e.g.:
sbatch --exclude=c36,c37 --mem=8G --time=01:00:00 --job-name=cdekm_cb_nhl --wrap="module load stata; stata-se -b do an_cdekm_combine.do nhl"

