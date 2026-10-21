*==============================================================================
* an_cdekm_combine.do
*
* Combines the bootstrap blocks from an_cdekm.do with the point estimates,
* and makes the results dataset with percentile CIs. Run after the point run
* and all block runs for a cancer have finished:
*
*   do an_cdekm_combine.do pan
*
* Inputs:  an_cdekm_PointEstimates_<cancer>.dta
*          an_cdekm_Bootstraps_<cancer>_b*.dta   (every block file found)
* Outputs: an_cdekm_Combine_<cancer>.log
*          an_cdekm_Bootstraps_<cancer>.dta        all replicates
*          an_cdekm_EstimatesAndBSCIs_<cancer>.dta cancertype estimand statistic
*            horizon rr lci uci n_boot maxsmd balance_ok balance_ok_upto
*            risk_exposed risk_unexposed
*          (estimand: CDE or Total; 'rr' holds the point estimate for both
*          statistics, RR and RD)
*==============================================================================
version 18
set more off

args cancertype_arg
local cancertype "bre"
if "`cancertype_arg'" != "" local cancertype "`cancertype_arg'"

include inc_cde_settings.do

capture log close cdecomb
log using "an_cdekm_Combine_`cancertype'", text replace name(cdecomb)
display as text "an_cdekm_combine.do   cancer: `cancertype'   " c(current_date) " " c(current_time)

capture confirm file "an_cdekm_PointEstimates_`cancertype'.dta"
if _rc {
	display as error "an_cdekm_PointEstimates_`cancertype'.dta not found - run the point run first (do an_cdekm.do `cancertype')"
	log close cdecomb
	exit 601
}

* ---- Append every block file ---------------------------------------------
local block_files : dir . files "an_cdekm_Bootstraps_`cancertype'_b*.dta"
if `"`block_files'"' == "" {
	display as error "No bootstrap block files an_cdekm_Bootstraps_`cancertype'_b*.dta found"
	log close cdecomb
	exit 601
}
clear
foreach f of local block_files {
	append using "`f'"
}
sort block replicate

display as text _n "Replicates per block (failed replicates are recorded as missing):"
tabulate block

* Blocks expected but not found
quietly levelsof block, local(found_blocks)
local missing_blocks
forvalues k = 1/$cde_n_blocks {
	if !`: list k in found_blocks' local missing_blocks `missing_blocks' `k'
}
if "`missing_blocks'" != "" display as error "WARNING: no file for block(s) `missing_blocks' - CIs use the replicates found"

duplicates report replicate
quietly duplicates tag replicate, generate(dup)
quietly count if dup > 0
if r(N) > 0 {
	display as error "Replicate numbers are duplicated - was cde_reps_per_block changed between block runs? Stopping."
	log close cdecomb
	exit 459
}
drop dup

* Blocks from the previous version (CDE only, ATE weights) must not be mixed
* in: they have rr_/rd_ but no trr_/trd_ results
local first_h : word 1 of $cde_horizons
local first_m = round(`first_h' * 12)
capture confirm variable trr_`first_m'
if _rc {
	display as error "No total-effect results in any block file: all blocks are from the previous version. Rerun the blocks."
	log close cdecomb
	exit 459
}
quietly count if !missing(rr_`first_m') & missing(trr_`first_m')
if r(N) > 0 {
	display as error "Some block files are from the previous version (CDE only) - delete them and rerun those blocks:"
	tabulate block if !missing(rr_`first_m') & missing(trr_`first_m')
	log close cdecomb
	exit 459
}

save "an_cdekm_Bootstraps_`cancertype'", replace
display as text "Total replicates: " _N

* ---- Percentile CIs ------------------------------------------------------
* Bootstrap variables: rr_m rd_m (CDE) and trr_m trd_m (total effect)
foreach h of global cde_horizons {
	local m = round(`h' * 12)
	foreach s in rr rd trr trd {
		local nboot_`s'_`m' = 0
		local lci_`s'_`m'   = .
		local uci_`s'_`m'   = .
		capture confirm variable `s'_`m'
		if _rc continue
		quietly count if !missing(`s'_`m')
		local nboot_`s'_`m' = r(N)
		if r(N) > 1 {
			_pctile `s'_`m', percentiles(2.5 97.5)
			local lci_`s'_`m' = r(r1)
			local uci_`s'_`m' = r(r2)
		}
	}
}

* ---- Results dataset -----------------------------------------------------
use "an_cdekm_PointEstimates_`cancertype'", clear
capture confirm variable estimand
if _rc {
	display as error "an_cdekm_PointEstimates_`cancertype' has no estimand variable - it is from the previous version; rerun the point run"
	log close cdecomb
	exit 459
}
gen double lci    = .
gen double uci    = .
gen int    n_boot = .
gen int    m      = round(horizon * 12)
forvalues i = 1/`=_N' {
	local s = lower(statistic[`i'])
	if estimand[`i'] == "Total" local s = "t`s'"
	local mm = m[`i']
	if "`nboot_`s'_`mm''" == "" | "`nboot_`s'_`mm''" == "0" {
		display as error "WARNING: no bootstrap results for `s'_`mm' (" estimand[`i'] ", horizon " horizon[`i'] ") - horizons changed, or blocks from the previous version?"
		continue
	}
	quietly replace lci    = `lci_`s'_`mm''   in `i'
	quietly replace uci    = `uci_`s'_`mm''   in `i'
	quietly replace n_boot = `nboot_`s'_`mm'' in `i'
}
drop m

capture confirm variable maxagediff
if _rc gen double maxagediff = .   /* point run from before the age criterion */
order cancertype estimand statistic horizon rr lci uci n_boot maxsmd maxagediff balance_ok balance_ok_upto risk_exposed risk_unexposed
label variable estimand        "CDE = no death (weighted KM); Total = death as competing event (weighted Aalen-Johansen)"
label variable statistic       "RR = risk ratio, RD = risk difference"
label variable horizon         "Years since index date"
label variable rr              "Point estimate (RR or RD)"
label variable lci             "Bootstrap 2.5th percentile"
label variable uci             "Bootstrap 97.5th percentile"
label variable n_boot          "Successful bootstrap replicates"
label variable maxsmd          "Max weighted |SMD| excluding age (CDE: over checks up to horizon; Total: at baseline)"
label variable maxagediff      "Max |weighted age difference|, years (CDE: over checks up to horizon; Total: at baseline)"
label variable balance_ok      "1 = max |SMD| < threshold and |age difference| within tolerance (CDE: up to horizon; Total: baseline)"
label variable balance_ok_upto "CDE: latest horizon with acceptable balance (years; 0 = none); Total: missing"
label variable risk_exposed    "Weighted risk, cancer survivors"
label variable risk_unexposed  "Weighted risk, comparators (reweighted)"
sort estimand statistic horizon
save "an_cdekm_EstimatesAndBSCIs_`cancertype'", replace
list, sepby(estimand statistic) noobs abbreviate(16)

log close cdecomb
