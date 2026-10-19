*==============================================================================
* inc_cde_settings.do
*
* Shared settings for an_cdekm.do and an_weightedCox.do, so the KM and Cox
* analyses always use the same data definitions and weight models.
* Included (not run) by the analysis files: edit here, not in the files.
*==============================================================================

* ---- Code version ----------------------------------------------------------
* pr_cde_programs.do, inc_cde_settings.do, an_cdekm.do and an_weightedCox.do
* each carry this stamp; the analysis files stop at once if the four do not
* agree (e.g. one file copied to the run folder but not the others). Change
* it in all four files whenever any of them changes.
global cde_code_version "2026-10-16c"

* ---- Output width ---------------------------------------------------------
* Batch mode defaults to about 80 characters, so wide tables (e.g. the
* balance tables) wrap with ">". 255 is Stata's maximum. Set here, before
* the analysis files open their logs, so it applies to every log.
set linesize 255

* ---- Paths (relative to the working directory the analysis file runs in) --
global cde_datadir ".."      /* folder with cr_dataforDEManalysis_AandG_<cancer>.dta */
global cde_incdir  "."      /* folder with inc_excludepriorandset_dementia.do */

* ---- Confounders (exposure model, death models, adjusted Cox) ------------
global baseline_confounders age i.gender i.region i.urban i.smokstatus i.imd20 i.alcohol_prob ///
	b_diab b_cvdgrouped b_ckd b_hypertension b_depression i.index_year_gr

* Time-updated predictors of death (death models only, not the outcome model)
global time_varying_death_predictors cvdgrouped_start_of_year

* Cancers whose exposed death model does NOT include stage
global cde_nostage "nhl leu mye"

* Cancers with no TNM stage where tumour grade stands in for it (exposed
* death models, age x stage term and the stage balance check), from the
* numeric grade variable in the analysis file (1-4, 99 = GX/missing),
* grouped by pr_cde_grade_as_stage as grade 1-2, 3, 4, GX/missing.
global cde_grade_as_stage "cns"
global cde_grade_var      "grade_cns"

* ---- Weight-update grid --------------------------------------------------
global cde_fine_per_year 4      /* quarterly ...                            */
global cde_fine_until    2      /* ... for the first 2 years, annual after   */

* ---- Death models --------------------------------------------------------
global death_time_knots "0.1 0.5 1 2 5"   /* spline knots, years since index */
global cde_split_exposed_death 1         /* 1 = exposed model fitted separately for year 1 and later */
global cde_death_link "cloglog"          /* cloglog (default, grouped-time PH with offset) or logit (sensitivity) */
global cde_age_knots     4               /* restricted cubic spline in age in the death models: knots (3, 4 or 5; 0 = linear age only) */
global cde_age_stage_int 1               /* 1 = age x stage interaction in the exposed death models (cancers with stage) */

* ---- Exposure weights: target population ---------------------------------
* ATT: the cancer survivors (exposed weight 1, comparators p/(1-p)).
* ATE: the combined sample (1/p, 1/(1-p)). Applies to both the CDE and the
* total effect. (The weighted Cox uses death weights only, so is unaffected.)
global cde_estimand "ATT"

* ---- End of data collection (potential follow-up, for the stage balance
* check). Same date as the study end in inc_excludepriorandset_dementia.do;
* the practice last collection date (lcd) is also used if in the data.
global cde_admin_end "29mar2021"

* ---- Weight switches and truncation --------------------------------------
* (switch a weight off, e.g. both off to check the KM reproduces sts list)
global CDEKMexposureweightson 1
global CDEKMdeathweightson    1
global cde_truncation_pct     100        /* 100 = none; e.g. 99 = truncate at 99th percentile */

* ---- KM horizons and balance checks --------------------------------------
global cde_horizons      "0.5 1 2 3 5 10 15"            /* years */
global cde_balance_times "0 0.25 0.5 1 2 3 5 10 15"     /* must include every horizon */
global cde_balance_continuous  "age b_diab b_cvdgrouped b_ckd b_hypertension b_depression"
* IMD in fifths for balance (imd5 is made in pr_cde_dataprep_grid); the
* weight models still use twentiles
global cde_balance_categorical "gender region urban smokstatus imd5 alcohol_prob index_year_gr"
global cde_smd_threshold 0.1
* Age is judged on the weighted mean difference in years (exposed minus
* unexposed) rather than its SMD: dementia risk rises so steeply with age
* that an SMD below 0.1 (about a year) can still bias the comparison
global cde_age_tol 0.5                   /* years */

* ---- Weighted Cox: cumulative windows from index (years) -----------------
global cde_cox_windows "0.5 1 2 5"

* ---- Bootstrap ------------------------------------------------------------
* Replicates are run in blocks (one block per SLURM array task, or all
* blocks in turn with: do an_cdekm.do <cancer> all). Block k runs replicates
* (k-1) x reps_per_block + 1 to k x reps_per_block from its own random-number
* stream (rngstream k), so results do not depend on how the blocks are run.
* Do not change reps_per_block once blocks have been run for a cancer.
global cde_reps_per_block 25
global cde_n_blocks       20      /* 20 x 25 = 500 replicates */
global cde_seed           20260921
