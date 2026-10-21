*==============================================================================
* an_cdekm.do
*
* Effect of cancer history on dementia diagnosis, risk scale, two estimands
* from the same data, exposure weights and bootstrap. One cancer per run.
*   CDE:   inverse probability of exposure x time-updated inverse probability
*          of censoring-by-death weighted Kaplan-Meier (risk if no-one died)
*   Total: inverse probability of exposure weighted Aalen-Johansen, death as
*          a competing event
* Exposure weights target the cancer survivors (ATT) by default
* ($cde_estimand in inc_cde_settings.do).
*
* Three ways to run (cancer type always the first argument):
*
*   do an_cdekm.do pan          POINT run: point estimates, curves, balance.
*                               (If SLURM_ARRAY_TASK_ID is set, a BLOCK run
*                               for that task number instead - see below.)
*
*   do an_cdekm.do pan 3        BLOCK run: bootstrap block 3 only, i.e.
*                               replicates 101-150 with 50 per block. Under a
*                               SLURM array the block number is taken from
*                               SLURM_ARRAY_TASK_ID, so the call is just
*                               stata-se -b do an_cdekm.do pan
*                               (a number given here overrides it, e.g. to
*                               rerun one failed block)
*
*   do an_cdekm.do pan all      ALL: point run, then every block in turn, then
*                               an_cdekm_combine.do (small cancers, one machine)
*
* The point run and the block runs are independent (each block run refits
* the point-estimate weight models once, for start values), so they can all
* be submitted at the same time. When all have finished, run
*   do an_cdekm_combine.do pan
* to make the results dataset. Block k uses random-number stream k, so the
* replicates are identical however the blocks are run.
*
* Needs, in the working directory: pr_cde_programs.do, inc_cde_settings.do
* (and an_cdekm_combine.do for the 'all' mode)
*
* Steps
*   1. Load data, inc_excludepriorandset_dementia.do, data management, and
*      split follow-up on the weight grid (quarterly for 2 years, then annual)
*   2. Weight models and CDE (KM) point estimates at all horizons (point)
*   3. Weighted cumulative incidence curves (CDE)                 (point)
*   3b. Total effect (Aalen-Johansen) point estimates and curves  (point)
*   4. Covariate balance over follow-up (tables in the log) and the horizon
*      up to which balance is acceptable: all |SMD| < threshold for the
*      variables other than age, and weighted age difference within
*      +/- $cde_age_tol years                                     (point)
*   5. Bootstrap block(s): Poisson(1) frequency weights per person (both
*      spells of a comparator who later develops cancer share one frequency),
*      all weight models refitted in each replicate; CDE and total effect
*      from the same replicate                                    (block)
*
* Outputs (all start an_cdekm_)
*   point run:
*     an_cdekm_<cancer>.log                     log incl. weight models and balance tables
*     an_cdekm_PointEstimates_<cancer>.dta      point estimates and balance flags (both estimands)
*     an_cdekm_Curve_<cancer>.dta               weighted cumulative incidence by estimand, group and time
*     an_cdekm_BalanceSummary_<cancer>.dta      max |SMD|, age difference and numbers at risk at each check time
*   block run k:
*     an_cdekm_<cancer>_b<k>.log
*     an_cdekm_Bootstraps_<cancer>_b<k>.dta     one row per replicate in the block
*                                               (rr_m rd_m = CDE, trr_m trd_m = total)
*   an_cdekm_combine.do:
*     an_cdekm_Combine_<cancer>.log
*     an_cdekm_Bootstraps_<cancer>.dta          all replicates
*     an_cdekm_EstimatesAndBSCIs_<cancer>.dta   cancertype estimand statistic horizon rr lci uci + balance
*==============================================================================
version 18
set more off

args cancertype_arg mode_arg
if "`cancertype_arg'"=="" {
	noi di as error "No cancer specified"
	error 198
}
if "`cancertype_arg'" != "" local cancertype "`cancertype_arg'"

macro drop cde_code_version cde_programs_version   /* no stale stamps from an earlier run */
run pr_cde_programs.do
include inc_cde_settings.do

* ---- Code version check: the four code files must come from the same set
local this_version "2026-10-16c"
if "$cde_code_version" != "`this_version'" | "$cde_programs_version" != "`this_version'" {
	display as error "Code version mismatch - copy all four code files to the run folder together:"
	display as error "  an_cdekm.do" _col(26) "`this_version'"
	display as error "  pr_cde_programs.do" _col(26) cond("$cde_programs_version" == "", "(no version stamp)", "$cde_programs_version")
	display as error "  inc_cde_settings.do" _col(26) cond("$cde_code_version" == "", "(no version stamp)", "$cde_code_version")
	exit 498
}
display as text "Code version `this_version' (all files agree)"

* ---- What to run ---------------------------------------------------------
local array_task : env SLURM_ARRAY_TASK_ID
local run_point 0
local blocks
if "`mode_arg'" == "all" {
	local run_point 1
	numlist "1/$cde_n_blocks"
	local blocks `r(numlist)'
}
else if "`mode_arg'" != "" {
	capture confirm integer number `mode_arg'
	if _rc | real("`mode_arg'") < 1 {
		display as error "Second argument must be a block number (1, 2, ...) or all - got: `mode_arg'"
		exit 198
	}
	local blocks `mode_arg'
}
else if "`array_task'" != "" {
	local blocks `array_task'
}
else local run_point 1

foreach block of local blocks {
	if `block' > $cde_n_blocks display as error "NOTE: block `block' is beyond cde_n_blocks ($cde_n_blocks); it will still be run and combined"
}

* Log: one per point run, one per block
if `run_point' local logname "an_cdekm_`cancertype'"
else           local logname "an_cdekm_`cancertype'_b`blocks'"
capture log close cdekm
log using "`logname'", text replace name(cdekm)

display as text "{hline 60}"
display as text "an_cdekm.do   cancer: `cancertype'   started " c(current_date) " " c(current_time)
if `run_point' display as text "Point estimates: yes"
if "`blocks'" != "" display as text "Bootstrap block(s): `blocks'  ($cde_reps_per_block replicates per block)"
display as text "Grid: $cde_fine_per_year per year for $cde_fine_until years, then annual; death model link: $cde_death_link"
display as text "Weights on: exposure $CDEKMexposureweightson ($cde_estimand), death $CDEKMdeathweightson; truncation pct $cde_truncation_pct"
display as text "{hline 60}"


*************************************************
* 1. Load, data management, grid
*************************************************
use "$cde_datadir/cr_dataforDEManalysis_AandG_`cancertype'", clear

local year = 0
local outcome "dementia"
include "$cde_incdir/inc_excludepriorandset_dementia.do"   /* excludes prior outcomes and stsets */

gen byte died_this_spell = 0
replace died_this_spell = 1 if dementia != 1 & !missing(dod) & doexit == dod
replace died_this_spell = 1 if dementia != 1 & missing(dod) & !missing(deathdate) & doexit == deathdate

replace region = 99 if missing(region)
* Missing stage as its own category, so it cannot produce missing weights
capture confirm variable stage_tnm
if !_rc replace stage_tnm = 99 if missing(stage_tnm)
* Grade in place of stage where there is no TNM stage ($cde_grade_as_stage)
pr_cde_grade_as_stage, cancertype(`cancertype')

pr_cde_dataprep_grid, fine_per_year($cde_fine_per_year) fine_until($cde_fine_until)

quietly summarize person_index, meanonly
local n_persons = r(max)
display as text "People (for the bootstrap): " `n_persons'
memory     /* for sizing --mem in the SLURM scripts (allow ~2x for the model fits) */


*************************************************
* POINT RUN: steps 2-4
*************************************************
if `run_point' {

	*************************************************
	* 2. Weight models and KM point estimates
	*************************************************
	pr_cde_weights, cancertype(`cancertype') savestart
	display as text _n "Weights: final mean " %6.3f r(weight_final_mean) ", p99 " %7.3f r(weight_final_p99) ", max " %8.3f r(weight_final_max)
	display as text "         death mean " %6.3f r(weight_death_mean) ", p99 " %7.3f r(weight_death_p99) ", max " %8.3f r(weight_death_max)

	pr_cde_km, horizons($cde_horizons)

	display as text _n "CDE (no death): point estimates"
	display as text %10s "horizon" %12s "risk exp" %12s "risk unexp" %10s "RR" %10s "RD"
	foreach h of global cde_horizons {
		local m = round(`h' * 12)
		local pt_risk1_`m' = r(risk1_`m')
		local pt_risk0_`m' = r(risk0_`m')
		local pt_rr_`m'    = r(rr_`m')
		local pt_rd_`m'    = r(rd_`m')
		display as result %10.2f `h' %12.4f r(risk1_`m') %12.4f r(risk0_`m') %10.3f r(rr_`m') %10.4f r(rd_`m')
	}


	*************************************************
	* 3. Weighted cumulative incidence curves
	*************************************************
	preserve
	keep if _st == 1 & event == 1
	gen double time_years = _t
	capture stset, clear
	keep exposed time_years km_survival
	collapse (min) km_survival, by(exposed time_years)
	local n_curve = _N
	set obs `=`n_curve' + 2'
	replace exposed     = 0 in `=`n_curve' + 1'
	replace exposed     = 1 in `=`n_curve' + 2'
	replace time_years  = 0 in `=`n_curve' + 1'/`=`n_curve' + 2'
	replace km_survival = 1 in `=`n_curve' + 1'/`=`n_curve' + 2'
	gen double cuminc = 1 - km_survival
	gen str3 cancertype = "`cancertype'"
	gen str5 estimand = "CDE"
	drop km_survival
	tempfile curve_cde
	save `curve_cde'
	restore


	*************************************************
	* 3b. Total effect: exposure-weighted Aalen-Johansen
	*************************************************
	pr_cde_cif, horizons($cde_horizons) keepcurve

	display as text _n "Total effect (death as a competing event): point estimates"
	display as text %10s "horizon" %12s "risk exp" %12s "risk unexp" %10s "RR" %10s "RD"
	foreach h of global cde_horizons {
		local m = round(`h' * 12)
		local pt_trisk1_`m' = r(trisk1_`m')
		local pt_trisk0_`m' = r(trisk0_`m')
		local pt_trr_`m'    = r(trr_`m')
		local pt_trd_`m'    = r(trd_`m')
		display as result %10.2f `h' %12.4f r(trisk1_`m') %12.4f r(trisk0_`m') %10.3f r(trr_`m') %10.4f r(trd_`m')
	}

	* Curves: CDE and total effect in one file (estimand = CDE / Total)
	frame cde_cif_curve {
		keep exposed time_years cif_dementia cif_death
		rename cif_dementia cuminc
		rename cif_death    cuminc_death
		local n_curve = _N
		quietly set obs `=`n_curve' + 2'
		quietly replace exposed      = 0 in `=`n_curve' + 1'
		quietly replace exposed      = 1 in `=`n_curve' + 2'
		quietly replace time_years   = 0 in `=`n_curve' + 1'/`=`n_curve' + 2'
		quietly replace cuminc       = 0 in `=`n_curve' + 1'/`=`n_curve' + 2'
		quietly replace cuminc_death = 0 in `=`n_curve' + 1'/`=`n_curve' + 2'
		gen str3 cancertype = "`cancertype'"
		gen str5 estimand = "Total"
		append using `curve_cde'
		order cancertype estimand exposed time_years cuminc cuminc_death
		sort estimand exposed time_years
		label variable cuminc       "Weighted cumulative incidence of dementia diagnosis"
		label variable cuminc_death "Total only: weighted cumulative incidence of death without dementia"
		label variable estimand "CDE = no death (weighted KM); Total = death as competing event (weighted Aalen-Johansen)"
		save "an_cdekm_Curve_`cancertype'", replace
	}
	frame drop cde_cif_curve


	*************************************************
	* 4. Covariate balance over follow-up
	*************************************************
	local stage_option
	capture confirm variable stage_tnm
	if !_rc & strpos(" $cde_nostage ", " `cancertype' ") == 0 local stage_option "stagevar(stage_tnm)"

	pr_cde_balance $cde_balance_continuous, times($cde_balance_times) ///
		categorical($cde_balance_categorical) `stage_option' potfu(potential_fu) ///
		agevar(age) agetol($cde_age_tol)
	matrix B = r(balance)

	* Over all check times up to each horizon: max |SMD| of the variables other
	* than age (column 2) and max |weighted age difference| in years (column
	* 5). Acceptable if max |SMD| < $cde_smd_threshold AND max |age difference|
	* <= $cde_age_tol years at every check (missing, e.g. a group with no-one
	* at risk, counts as not acceptable)
	local n_checks = rowsof(B)
	local ok_upto = 0
	foreach h of global cde_horizons {
		local m = round(`h' * 12)
		local maxsmd_`m' = 0
		local maxage_`m' = 0
		local covered = 0
		forvalues i = 1/`n_checks' {
			if B[`i', 1] <= `h' + 1e-9 {
				if missing(B[`i', 2]) local maxsmd_`m' = .
				else if !missing(`maxsmd_`m'') & B[`i', 2] > `maxsmd_`m'' local maxsmd_`m' = B[`i', 2]
				if missing(B[`i', 5]) local maxage_`m' = .
				else if !missing(`maxage_`m'') & abs(B[`i', 5]) > `maxage_`m'' local maxage_`m' = abs(B[`i', 5])
				if abs(B[`i', 1] - `h') < 1e-9 local covered = 1
			}
		}
		if !`covered' display as error "WARNING: horizon `h' is not among the balance check times"
		local ok_`m' = (`maxsmd_`m'' < $cde_smd_threshold) & (`maxage_`m'' <= $cde_age_tol)
		if `ok_`m'' local ok_upto = `h'
	}
	display as text _n "Balance acceptable (all |SMD| < $cde_smd_threshold, and |age difference| <= $cde_age_tol years, at every check up to the horizon) up to: " `ok_upto' " years"

	* Total effect: only BASELINE balance applies (exposure weights only; the
	* at-risk population is meant to change as people die), i.e. the check at t = 0
	local maxsmd_base = .
	local maxage_base = .
	forvalues i = 1/`n_checks' {
		if abs(B[`i', 1]) < 1e-9 {
			local maxsmd_base = B[`i', 2]
			local maxage_base = abs(B[`i', 5])
		}
	}
	if missing(`maxsmd_base') display as error "WARNING: t = 0 is not among the balance check times; baseline balance for the total effect not available"
	local ok_base = (`maxsmd_base' < $cde_smd_threshold) & (`maxage_base' <= $cde_age_tol)
	display as text "Baseline balance (total effect): max |SMD| = " %6.3f `maxsmd_base' ", |age difference| = " %5.2f `maxage_base' " years"

	preserve
	clear
	svmat double B, names(col)
	rename time check_time
	gen str3 cancertype = "`cancertype'"
	order cancertype
	label variable maxsmd  "Max |SMD| (weighted, excluding age) among those at risk at check_time"
	label variable agediff "Weighted mean age difference (exposed - unexposed), years, at check_time"
	label variable n_unexp "Records at risk, unexposed"
	label variable n_exp   "Records at risk, exposed"
	save "an_cdekm_BalanceSummary_`cancertype'", replace
	restore

	* Point estimates and balance flags, for an_cdekm_combine.do
	* Total-effect rows carry baseline balance only (balance_ok_upto missing)
	tempname pt
	postfile `pt' str3 cancertype str5 estimand str2 statistic float horizon double(rr risk_exposed risk_unexposed maxsmd maxagediff) ///
		byte balance_ok float balance_ok_upto using "an_cdekm_PointEstimates_`cancertype'", replace
	foreach h of global cde_horizons {
		local m = round(`h' * 12)
		foreach s in rr rd {
			local stat = upper("`s'")
			post `pt' ("`cancertype'") ("CDE") ("`stat'") (`h') (`pt_`s'_`m'') (`pt_risk1_`m'') (`pt_risk0_`m'') ///
				(`maxsmd_`m'') (`maxage_`m'') (`ok_`m'') (`ok_upto')
			post `pt' ("`cancertype'") ("Total") ("`stat'") (`h') (`pt_t`s'_`m'') (`pt_trisk1_`m'') (`pt_trisk0_`m'') ///
				(`maxsmd_base') (`maxage_base') (`ok_base') (.)
		}
	}
	postclose `pt'
	display as text _n "Point estimates saved: an_cdekm_PointEstimates_`cancertype'"
}


*************************************************
* 5. Bootstrap block(s)
*************************************************
if "`blocks'" != "" {

	* Start values: the point-estimate weight models (already fitted in the
	* 'all' mode; fitted once here in a block run - about one replicate's time)
	if !`run_point' {
		display as text _n "Fitting the point-estimate weight models (start values for the replicates), " c(current_time)
		quietly pr_cde_weights, cancertype(`cancertype') savestart
		display as text "Weights: final mean " %6.3f r(weight_final_mean) ", p99 " %7.3f r(weight_final_p99) ", max " %8.3f r(weight_final_max) ", " c(current_time)
	}

	local bs_vars
	local bs_exprs
	local bs_missing
	* CDE (from pr_cde_km) and total effect (from pr_cde_cif); the KM results
	* are held in locals because pr_cde_cif replaces r()
	local km_vars
	local km_missing
	local tot_vars
	local tot_exprs
	foreach h of global cde_horizons {
		local m = round(`h' * 12)
		local km_vars    `km_vars' rr_`m' rd_`m'
		local km_missing `km_missing' (.) (.)
		local tot_vars   `tot_vars' trr_`m' trd_`m'
		local tot_exprs  `tot_exprs' (r(trr_`m')) (r(trd_`m'))
	}
	local bs_vars    `km_vars' `tot_vars'
	local bs_missing `km_missing' `km_missing'

	foreach block of local blocks {
		local first_rep = (`block' - 1) * $cde_reps_per_block + 1
		local last_rep  = `block' * $cde_reps_per_block
		display as text _n "{hline 60}"
		display as text "Block `block': replicates `first_rep' to `last_rep', started " c(current_date) " " c(current_time)

		* Own random-number stream per block (Stata's mt64s generator), so a
		* block gives the same replicates whether run alone or in sequence
		set rng mt64s
		set rngstream `block'
		set seed $cde_seed

		tempname bs
		postfile `bs' int(block replicate) double(`bs_vars') ///
			using "an_cdekm_Bootstraps_`cancertype'_b`block'", replace

		timer clear
		timer on 1
		forvalues b = `first_rep'/`last_rep' {
			* Poisson(1) frequency per PERSON, drawn in Mata and mapped to
			* records through person_index (no sorting needed)
			timer on 2
			capture drop bootstrap_frequency
			quietly gen int bootstrap_frequency = .
			mata: cde_freq = rpoisson(`n_persons', 1, 1)
			mata: st_store(., "bootstrap_frequency", cde_freq[st_data(., "person_index")])
			mata: mata drop cde_freq
			timer off 2

			timer on 3
			capture quietly pr_cde_weights, cancertype(`cancertype') bootweight(bootstrap_frequency) usestart
			local rc = _rc
			timer off 3

			timer on 4
			if !`rc' {
				capture quietly pr_cde_km, horizons($cde_horizons) bootweight(bootstrap_frequency)
				local rc = _rc
			}
			local km_exprs
			if !`rc' {
				foreach h of global cde_horizons {
					local m = round(`h' * 12)
					local km_exprs `km_exprs' (`=r(rr_`m')') (`=r(rd_`m')')
				}
			}
			timer off 4

			timer on 5
			if !`rc' {
				capture quietly pr_cde_cif, horizons($cde_horizons) bootweight(bootstrap_frequency)
				local rc = _rc
				if !`rc' post `bs' (`block') (`b') `km_exprs' `tot_exprs'
			}
			timer off 5

			if `rc' {
				display as error "Replicate `b' failed (rc = `rc'): recorded as missing"
				post `bs' (`block') (`b') `bs_missing'
			}

			local done = `b' - `first_rep' + 1
			if mod(`done', 10) == 0 | `done' == 1 {
				timer off 1
				quietly timer list 1
				display as text "`cancertype' block `block': replicate `b' (`done' of $cde_reps_per_block) done, " ///
					%7.1f r(t1) / `done' " s per replicate, " c(current_time)
				timer on 1
			}
		}
		timer off 1
		postclose `bs'

		quietly timer list
		local nr = $cde_reps_per_block
		display as text _n "Block `block' finished " c(current_date) " " c(current_time) ". Mean seconds per replicate:"
		display as text "  frequency draw " %8.1f r(t2) / `nr'
		display as text "  weight models  " %8.1f r(t3) / `nr'
		display as text "  KM (CDE)       " %8.1f r(t4) / `nr'
		display as text "  A-J (total)    " %8.1f r(t5) / `nr'
		display as text "  total          " %8.1f r(t1) / `nr'
	}
}


*************************************************
* 'all' mode: combine now
*************************************************
if "`mode_arg'" == "all" {
	do an_cdekm_combine.do `cancertype'
}

display as text _n "an_cdekm.do   cancer: `cancertype'   finished " c(current_date) " " c(current_time)
log close cdekm
