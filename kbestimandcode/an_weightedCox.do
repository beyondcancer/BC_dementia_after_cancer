*==============================================================================
* an_weightedCox.do
*
* Death-weighted, covariate-adjusted Cox model (cause-specific hazard ratio
* with inverse probability of censoring-by-death weights), over cumulative
* windows of follow-up from the index date (0-6m, 0-1y, 0-2y, 0-5y by
* default: $cde_cox_windows), matching the cumulative windows in the paper.
* One cancer per run. Uses exactly the same data preparation and death
* models as an_cdekm.do (shared settings in inc_cde_settings.do).
*
* Run:   do an_weightedCox.do pan        all windows in $cde_cox_windows, in turn
*        do an_weightedCox.do pan 5      one window only (0-5 years), e.g. to
*                                        run the windows as separate cluster jobs
*
* Needs, in the working directory: pr_cde_programs.do, inc_cde_settings.do
*
* Models, for each window (each record its own left-truncated subject, so
* the weight can change from interval to interval; follow-up stopped at the
* end of the window, which is administrative censoring):
*   weighted = 1  Death-weighted (weight_death only, no exposure weights, so
*                 the estimate stays conditional on covariates), robust SEs
*                 clustered on person. This is the slow part.
*   weighted = 0  Unweighted comparator on the same records and covariates,
*                 model-based SEs (fast). Switch off below if not needed.
* The whole-follow-up model is switched off (run_alltime 0): its results
* from the previous run can be appended to these.
*
* Outputs (all start an_weightedCox_)
*   an_weightedCox_<cancer>[_w<window>].log
*   an_weightedCox_Estimates_<cancer>[_w<window>].dta
*       cancertype statistic horizon rr lci uci weighted n_events
*       (statistic = "HR"; horizon = end of the window in years; missing =
*       whole follow-up). "_w<window>" only when a single window is given,
*       with "." written as "p" (e.g. _w0p5 for 6 months).
*==============================================================================
version 18
set more off

args cancertype_arg window_arg
if "`cancertype_arg'"=="" {
	error 99
	noi di as error "No cancer specified"
}
if "`cancertype_arg'" != "" local cancertype "`cancertype_arg'"

local run_unweighted 0                                   /* 1 = also fit the unweighted comparator */
local run_alltime    0                                   /* 1 = also fit the whole-follow-up model */

macro drop cde_code_version cde_programs_version   /* no stale stamps from an earlier run */
run pr_cde_programs.do
include inc_cde_settings.do

* ---- Code version check: the four code files must come from the same set
local this_version "2026-10-16c"
if "$cde_code_version" != "`this_version'" | "$cde_programs_version" != "`this_version'" {
	display as error "Code version mismatch - copy all four code files to the run folder together:"
	display as error "  an_weightedCox.do" _col(26) "`this_version'"
	display as error "  pr_cde_programs.do" _col(26) cond("$cde_programs_version" == "", "(no version stamp)", "$cde_programs_version")
	display as error "  inc_cde_settings.do" _col(26) cond("$cde_code_version" == "", "(no version stamp)", "$cde_code_version")
	exit 498
}
display as text "Code version `this_version' (all files agree)"

* Windows to fit
local windows $cde_cox_windows
local suffix
if "`window_arg'" != "" {
	capture confirm number `window_arg'
	if _rc | real("`window_arg'") <= 0 {
		display as error "Second argument must be a window length in years (e.g. 0.5, 1, 2, 5) - got: `window_arg'"
		exit 198
	}
	local windows `window_arg'
	* no "." in file names (Stata would read it as an extension): 0.5 -> 0p5
	local suffix = "_w" + subinstr("`window_arg'", ".", "p", .)
}

capture log close wcox
log using "an_weightedCox_`cancertype'`suffix'", text replace name(wcox)

display as text "{hline 60}"
display as text "an_weightedCox.do   cancer: `cancertype'   started " c(current_date) " " c(current_time)
display as text "Windows (years from index): `windows'" cond(`run_alltime', " plus whole follow-up", "")
display as text "Grid: $cde_fine_per_year per year for $cde_fine_until years, then annual; death weights $CDEKMdeathweightson"
display as text "{hline 60}"


*************************************************
* 1. Load, data management, grid (as in an_cdekm.do)
*************************************************
use "$cde_datadir/cr_dataforDEManalysis_AandG_`cancertype'", clear

local year = 0
local outcome "dementia"
include "$cde_incdir/inc_excludepriorandset_dementia.do"   /* excludes prior outcomes and stsets */

gen byte died_this_spell = 0
replace died_this_spell = 1 if dementia != 1 & !missing(dod) & doexit == dod
replace died_this_spell = 1 if dementia != 1 & missing(dod) & !missing(deathdate) & doexit == deathdate

replace region = 99 if missing(region)
capture confirm variable stage_tnm
if !_rc replace stage_tnm = 99 if missing(stage_tnm)
* Grade in place of stage where there is no TNM stage ($cde_grade_as_stage)
pr_cde_grade_as_stage, cancertype(`cancertype')

pr_cde_dataprep_grid, fine_per_year($cde_fine_per_year) fine_until($cde_fine_until)


*************************************************
* 2. Weight models (the KM is not run here)
*************************************************
* Fitted on ALL follow-up, exactly as in an_cdekm.do, so the weights inside
* each window are identical to the CDE analysis (a record's death weight
* depends only on earlier intervals)
pr_cde_weights, cancertype(`cancertype')
display as text _n "Death weights: mean " %6.3f r(weight_death_mean) ", p99 " %7.3f r(weight_death_p99) ", max " %8.3f r(weight_death_max)

* Records starting after the longest window play no part in any window
* model: drop them so the Cox fits work on less data (unless the
* whole-follow-up model is wanted)
if !`run_alltime' {
	local max_window = 0
	foreach w of local windows {
		if `w' > `max_window' local max_window = `w'
	}
	quietly count
	local n_before = r(N)
	quietly drop if tstart >= `max_window'
	display as text "Records kept for windows up to " `max_window' " years: " _N " of " `n_before'
}


*************************************************
* 3. Cox models
*************************************************
tempname res
postfile `res' str3 cancertype str2 statistic float horizon double(rr lci uci) byte weighted long n_events ///
	using "an_weightedCox_Estimates_`cancertype'`suffix'", replace

* Same records for both models: those with a death weight
quietly count if missing(weight_death)
if r(N) > 0 display as error "NOTE: " r(N) " records have a missing death weight and are excluded from both models"

local fits `windows'
if `run_alltime' local fits `fits' .

timer clear
foreach w of local fits {
	if "`w'" == "." {
		local exit_opt
		local label "whole follow-up"
	}
	else {
		local exit_opt "exit(time `w')"
		local label "0-`w' years"
	}
	display as text _n "{hline 60}" _n "Window: `label'   " c(current_time)

	* ---- Death-weighted, covariate-adjusted ------------------------------
	timer on 1
	quietly stset tstop if !missing(weight_death) [pweight = weight_death], failure(event) enter(time tstart) `exit_opt'
	stcox exposed $baseline_confounders, vce(cluster e_patid)
	local b  = _b[exposed]
	local se = _se[exposed]
	post `res' ("`cancertype'") ("HR") (`w') (exp(`b')) (exp(`b' - invnormal(0.975) * `se')) (exp(`b' + invnormal(0.975) * `se')) (1) (e(N_fail))
	display as result "Death-weighted adjusted HR, `label': " %5.3f exp(`b') " (" %5.3f exp(`b' - invnormal(0.975) * `se') " to " %5.3f exp(`b' + invnormal(0.975) * `se') ")"
	timer off 1
	quietly timer list 1
	display as text "  (" %7.0f r(t1) " s so far for the weighted fits)"

	* ---- Unweighted comparator, same records and covariates -------------
	if `run_unweighted' {
		quietly stset tstop if !missing(weight_death), failure(event) enter(time tstart) `exit_opt'
		quietly stcox exposed $baseline_confounders
		local b  = _b[exposed]
		local se = _se[exposed]
		post `res' ("`cancertype'") ("HR") (`w') (exp(`b')) (exp(`b' - invnormal(0.975) * `se')) (exp(`b' + invnormal(0.975) * `se')) (0) (e(N_fail))
		display as result "Unweighted adjusted HR,     `label': " %5.3f exp(`b') " (" %5.3f exp(`b' - invnormal(0.975) * `se') " to " %5.3f exp(`b' + invnormal(0.975) * `se') ")"
	}
}

postclose `res'

use "an_weightedCox_Estimates_`cancertype'`suffix'", clear
label variable statistic "HR = cause-specific hazard ratio"
label variable horizon   "End of cumulative window from index (years); missing = whole follow-up"
label variable rr        "Point estimate"
label variable weighted  "1 = weighted for censoring by death, 0 = unweighted comparator"
label variable n_events  "Dementia events in the model"
sort weighted horizon
save, replace
list, sepby(weighted) noobs abbreviate(16)

display as text _n "an_weightedCox.do   cancer: `cancertype'   finished " c(current_date) " " c(current_time)
log close wcox
