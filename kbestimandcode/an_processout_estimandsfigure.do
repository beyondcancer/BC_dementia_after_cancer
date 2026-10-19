*==============================================================================
* an_processout_estimandsfigure.do
*
* Figure: dementia in cancer survivors vs matched comparators, by cancer,
* cumulative follow-up window and estimand, one panel per cancer.
*   CSHR   original Cox HR (cause-specific, descriptive)
*   CDEHR  death-weighted Cox HR
*   CDE    controlled direct effect risk ratio (death-weighted KM)
*   Total  total effect risk ratio (Aalen-Johansen, death competing)
*
* Input: one row per cancertype x horizon x estimand, with variables
*   cancertype horizon rr lci uci estimand balance_ok
* (.dta, or a tab/comma-delimited text file with those column names)
*
* Settings below: layout (estimands clustered within each follow-up window,
* or one block per estimand showing the ratio over time), how to show
* estimates with unacceptable covariate balance (fade / grey / suppress),
* whether the death-weighted Cox HR takes the CDE balance flag, panel order
* (lethality / ICD-10 / alphabetical), axis, horizons, cancers to leave out.
*==============================================================================
version 18
set more off

* ---- Settings ---------------------------------------------------------------
local layout      "estimand"     /* time     = x axis is follow-up; the estimands are
                                           side by side within each window
                                estimand = one block per estimand, showing
                                           the ratio over follow-up within it */
local connect     1          /* 1 = join each estimand's points across follow-up */
local poorbal     "fade"     /* fade     = same colour, hollow and pale
                                grey     = hollow, light grey
                                suppress = not shown                        */
local cdehr_bal   1          /* 1 = death-weighted Cox HR takes the CDE balance
                                flag at the same horizon (same death weights);
                                0 = use its own balance_ok as supplied        */
local order       "icd10" /* lethality = panels ordered by 5-year total-effect
                                 RR, least lethal first; icd10 = by ICD-10
                                 code; alpha = by name                        */
local yaxis       "common"   /* common = same y axis in every panel; free     */
local ymin        0.05       /* y-axis range (log scale); CIs beyond are cut   */
local ymax        6
local horizons    "0.5 1 2 5 10"   /* horizons to show, in order (years)       */
local dropcancers ""         /* cancer codes to leave out, e.g. "cns"          */

* Colours (colour-blind safe) and marker symbols, one per estimand
local c1 "90 90 90"          /* CSHR:  dark grey  */
local c2 "213 94 0"          /* CDEHR: vermillion */
local c3 "0 114 178"         /* CDE:   blue       */
local c4 "0 158 115"         /* Total: green      */
local s1 S
local s2 D
local s3 O
local s4 T
local lab1 "Cox HR, original (cause-specific)"
local lab2 "Cox HR, death-weighted"
local lab3 "CDE risk ratio"
local lab4 "Total effect risk ratio"
* Short names, above each block in the estimand layout
local short1 "Cox"
local short2 "DW Cox"
local short3 "CDE"
local short4 "Total"


* ---- Data -------------------------------------------------------------------

use "$results_an_dem/an_Secondary_timesinceDx_cox_processout_dementia", clear
rename cancer cancertype
rename hr rr
gen horizon=real(year)
order cancer horizon
drop db outcome beta sebeta year
gen estimand = "CSHR"
gen statistic = "HR"
append using "$results_an_dem/hpc_output/results/an_cdekm_EstimatesAndBSCIs"

append using "$results_an_dem/hpc_output/results/an_WeightedCox_Estimates"
replace estimand = "CDEHR" if estimand==""

drop if statistic=="RD"
sort cancertype estimand horizon

by cancertype: gen x = _n

gen estimandfull = estimand + string(horizon)

replace balance_ok = 1 if balance_ok==.

keep if horizon==0.5|horizon==1|horizon==2|horizon==5|horizon==10

* Estimand order within each horizon
gen byte est = .
replace est = 1 if estimand == "CSHR"
replace est = 2 if estimand == "CDEHR"
replace est = 3 if estimand == "CDE"
replace est = 4 if estimand == "Total"
quietly count if missing(est)
if r(N) > 0 {
	display as error "Note: " r(N) " rows with an unrecognised estimand dropped"
	drop if missing(est)
}

* Horizon positions, in the order given in `horizons'
gen byte hpos = .
local k = 0
foreach h of local horizons {
	local ++k
	replace hpos = `k' if abs(horizon - `h') < 1e-6
	local hl`k' = cond(`h' < 1, string(`h' * 12) + "m", string(`h') + "y")
}
local nh = `k'
drop if missing(hpos)

* x positions, labels and separators for the chosen layout
local xlab
local xlines
local blocktext
if "`layout'" == "estimand" {
	* One block per estimand (nh positions plus a gap), horizons within it
	local bw = `nh' + 1
	gen double xpos = (est - 1) * `bw' + hpos
	forvalues e = 1/4 {
		forvalues k = 1/`nh' {
			local xlab `"`xlab' `=(`e' - 1) * `bw' + `k'' "`hl`k''""'
		}
		if `e' < 4 local xlines `xlines' `=`e' * `bw''
		local blocktext `"`blocktext' text(`ymax' `=(`e' - 1) * `bw' + (`nh' + 1) / 2' "`short`e''", placement(s) size(vsmall) color("`c`e''"))"'
	}
	local xmin = 0.3
	local xmax = 4 * `bw' - 0.3
	local xlabopt labsize(tiny) angle(90) noticks
	local xtitletext "Cumulative follow-up from cancer diagnosis, within each estimand"
}
else {
	* Follow-up windows along the axis, estimands side by side within each
	gen double xpos = hpos + (est - 2.5) * 0.19
	forvalues k = 1/`nh' {
		local xlab `"`xlab' `k' "`hl`k''""'
		if `k' < `nh' local xlines `xlines' `=`k' + 0.5'
	}
	local xmin = 0.5
	local xmax = `nh' + 0.5
	local xlabopt labsize(vsmall) noticks
	local xtitletext "Cumulative follow-up from cancer diagnosis"
}

* Balance: death-weighted Cox HR takes the CDE flag at the same horizon
if `cdehr_bal' {
	tempvar cdeok
	bysort cancertype horizon: egen `cdeok' = max(cond(est == 3, balance_ok, .))
	replace balance_ok = `cdeok' if est == 2 & !missing(`cdeok')
	drop `cdeok'
}
gen byte good = (balance_ok == 1)
if "`poorbal'" == "suppress" drop if !good

* Cut CIs at the axis limits
replace lci = `ymin' if lci < `ymin'
replace uci = `ymax' if uci > `ymax'
drop if rr < `ymin' | rr > `ymax'

* Panel names with ICD-10 codes, as in the paper
gen str40 cname = ""
replace cname = "Bladder (C67)"              if cancertype == "bla"
replace cname = "Breast (C50)"               if cancertype == "bre"
replace cname = "Cervix (C53)"               if cancertype == "cer"
replace cname = "CNS (C71-72)"               if cancertype == "cns"
replace cname = "Colorectal (C18-21)"        if cancertype == "col"
replace cname = "Stomach (C16)"              if cancertype == "gas"
replace cname = "Kidney (C64-65)"            if cancertype == "kid"
replace cname = "Leukaemia (C91-95)"         if cancertype == "leu"
replace cname = "Liver (C22)"                if cancertype == "liv"
replace cname = "Lung (C34)"                 if cancertype == "lun"
replace cname = "Malignant melanoma (C43)"   if cancertype == "mel"
replace cname = "Multiple myeloma (C90)"     if cancertype == "mye"
replace cname = "NHL (C82-85)"               if cancertype == "nhl"
replace cname = "Oesophagus (C15)"           if cancertype == "oes"
replace cname = "Oral cavity (C00-06)"       if cancertype == "ora"
replace cname = "Ovary (C56)"                if cancertype == "ova"
replace cname = "Pancreas (C25)"             if cancertype == "pan"
replace cname = "Prostate (C61)"             if cancertype == "pro"
replace cname = "Thyroid (C73)"              if cancertype == "thy"
replace cname = "Uterus (C54-55)"            if cancertype == "ute"
replace cname = cancertype    if cname == ""

* Panel order
if "`order'" == "lethality" {
	* 5-year total-effect RR (or the latest horizon available), descending
	bysort cancertype: egen double sortkey = max(cond(est == 4 & abs(horizon - 5) < 1e-6, rr, .))
	replace sortkey = -sortkey
}
else if "`order'" == "icd10" {
	* First ICD-10 code of each site
	gen double sortkey = .
	replace sortkey = 0    if cancertype == "ora"   /* C00-06  */
	replace sortkey = 15   if cancertype == "oes"   /* C15     */
	replace sortkey = 16   if cancertype == "gas"   /* C16     */
	replace sortkey = 18   if cancertype == "col"   /* C18-21  */
	replace sortkey = 22   if cancertype == "liv"   /* C22     */
	replace sortkey = 25   if cancertype == "pan"   /* C25     */
	replace sortkey = 34   if cancertype == "lun"   /* C34     */
	replace sortkey = 43   if cancertype == "mel"   /* C43     */
	replace sortkey = 50   if cancertype == "bre"   /* C50     */
	replace sortkey = 53   if cancertype == "cer"   /* C53     */
	replace sortkey = 54   if cancertype == "ute"   /* C54-55  */
	replace sortkey = 56   if cancertype == "ova"   /* C56     */
	replace sortkey = 61   if cancertype == "pro"   /* C61     */
	replace sortkey = 64   if cancertype == "kid"   /* C64-65  */
	replace sortkey = 67   if cancertype == "bla"   /* C67     */
	replace sortkey = 71   if cancertype == "cns"   /* C71-72  */
	replace sortkey = 73   if cancertype == "thy"   /* C73     */
	replace sortkey = 82   if cancertype == "nhl"   /* C82-85  */
	replace sortkey = 90   if cancertype == "mye"   /* C90     */
	replace sortkey = 91   if cancertype == "leu"   /* C91-95  */
	replace sortkey = 999  if missing(sortkey)
}
else gen double sortkey = 0
preserve
keep cancertype cname sortkey
duplicates drop
sort sortkey cname
gen int panel = _n
tempfile panels
save `panels'
restore
merge m:1 cancertype using `panels', nogenerate
capture label drop panel_lbl
quietly levelsof panel, local(plist)
foreach p of local plist {
	quietly levelsof cname if panel == `p', local(nm) clean
	label define panel_lbl `p' "`nm'", modify
}
label values panel panel_lbl


* ---- Graph ------------------------------------------------------------------
local plots
local n = 0
local legend_order
local poor_leg
* Thin lines joining each estimand's points across follow-up (drawn first,
* so the markers sit on top)
if `connect' {
	sort panel est hpos
	forvalues e = 1/4 {
		quietly count if est == `e'
		if r(N) > 0 {
			local plots `plots' (line rr xpos if est == `e', lcolor("`c`e''%45") lwidth(thin) connect(L))
			local ++n
		}
	}
}
forvalues e = 1/4 {
	quietly count if est == `e' & good
	if r(N) > 0 {
		local plots `plots' (rcap lci uci xpos if est == `e' & good, lcolor("`c`e''") lwidth(thin) msize(tiny))
		local ++n
		local plots `plots' (scatter rr xpos if est == `e' & good, msymbol(`s`e'') mcolor("`c`e''") msize(small))
		local ++n
		local legend_order `"`legend_order' `n' "`lab`e''""'
	}
	if "`poorbal'" != "suppress" {
		quietly count if est == `e' & !good
		if r(N) > 0 {
			if "`poorbal'" == "grey" local pc "gs11"
			else local pc "`c`e''%40"
			local plots `plots' (rcap lci uci xpos if est == `e' & !good, lcolor("`pc'") lwidth(thin) msize(tiny))
			local ++n
			local plots `plots' (scatter rr xpos if est == `e' & !good, msymbol(`s`e''h) mcolor("`pc'") msize(small))
			local ++n
			if "`poor_leg'" == "" local poor_leg `n'
		}
	}
}
if "`poor_leg'" != "" local legend_order `"`legend_order' `poor_leg' "Hollow markers: covariates not adequately balanced after weighting*""'

*local balnote "CDE balance: all |SMD| < 0.1 and weighted age differences within 0.5 years."
if "`poorbal'" == "suppress" local balnote "`balnote' Estimates with unacceptable balance are not shown."

local xlineopt
if "`xlines'" != "" local xlineopt xline(`xlines', lcolor(gs14) lwidth(vthin))
local yres
if "`yaxis'" == "free" local yres yrescale

twoway `plots', ///
	yline(1, lcolor(gs6) lwidth(thin)) ///
	`xlineopt' ///
	yscale(log range(`ymin' `ymax')) ///
	ylabel(0.1 "0.1" 0.25 "0.25" 0.5 "0.5" 1 "1" 2 "2" 4 "4", angle(0) labsize(vsmall) grid glcolor(gs15) glwidth(vthin)) ///
	xscale(range(`xmin' `xmax')) ///
	xlabel(`xlab', `xlabopt') ///
	`blocktext' ///
	xtitle("`xtitletext'", size(small)) ///
	ytitle("Ratio, cancer survivors vs comparators (log scale)", size(small)) ///
	legend(order(`legend_order') size(vsmall) symxsize(small) region(lcolor(none))) ///
	subtitle(, size(small) fcolor(gs14) lcolor(none)) ///
	by(panel, cols(4) `yres' compact imargin(small) ///
		note("`balnote'", size(vsmall)) ///
		legend(position(6)) graphregion(color(white))) ///
	xsize(7.5) ysize(10) name(cde_results, replace)

graph export "$results_an_dem/hpc_output/results/an_processout_estimandsfigure.emf", replace

