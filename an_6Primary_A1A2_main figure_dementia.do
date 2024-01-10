
capture log close
*log using "$logfiles\an_Primary_A1A2_main figure.txt", replace text

/*******  PRIMARY ANALYSIS AIM 1 / 2 agesex_adj INCIDENCE RATES, agesex_adj AND ADUSTED HRS  *****
Main figure - agesex_adj and adjusted hrs for each outcome group, with agesex_adj incidence
rates for cancer survivors and controls and HR (95% CI) displayed

individual outcome graphs included for supplementary appendix
*******************************************************************************/

/***** CREATE FILES WITH HR, LCI, UCI, HR (95% CI), Incidence rates (cancer
survivors and controls  *********************** */

/*KB 25/2 I added to the "post" to capture the number of events, and the agesex_adj incidences */
foreach year in 0 {
foreach db of  global databases {
*
foreach outcome in dementia vasc alz other_dem ns_dem  dementiadrugs dementiahes {

use "$results_an_dem/an_Primary_A1_crude-incidence_nofailures_`outcome'", clear

	noi dib "`outcome'", stars
	capture postutil clear
	tempfile estimates
	postfile estimates str8 outcome str8 model str3 cancersite  str3 year  nfail irexp irunexp hr lci uci pval using "`estimates'"
	*local i = 1
	foreach model in crude agesex_adj adjusted {
		dib "`model'", ul
		foreach site of global cancersites {
			dib "`site'", ul
			summ nfail if cancersite=="`site'" & outcome=="`outcome'" & db=="`db'"  & year=="`year'"
			local nfail = r(mean)
			summ rateexp if cancersite=="`site'" & outcome=="`outcome'" & db=="`db'"   & year=="`year'"
			local irexp = r(mean)
			summ rateunexp if cancersite=="`site'" & outcome=="`outcome'" & db=="`db'"   & year=="`year'"
			local irunexp = r(mean)
			capture noisily {
				estimates use "$results_an_dem/an_Primary_A2_cox-model-estimates_`model'_`site'_`outcome'_`db'_`outcome'_`year'"
				}
			if _rc==0 {
				lincom exposed, hr
				post estimates ("`outcome'")  ("`model'") ("`site'") ("`year'") (`nfail') (`irexp') (`irunexp') (r(estimate)) (r(lb)) (r(ub)) (r(p))
				}
				else {
					post estimates ("`outcome'")  ("`model'") ("`site'")  ("`year'")  (`nfail') (`irexp') (`irunexp') (.) (.) (.) (.)
					}
			}
		}

	postclose estimates
	use `estimates', clear
	list
	gen result  = string(hr, "%9.2fc") + " (" + string(lci, "%9.2fc") + "-" + string(uci, "%9.2fc") + ")"
	for var irexp irunexp: replace X = 1000*X 
	gen irboth = string(irexp, "%3.2f") + "/" + string(irunexp, "%3.2f")
	
	save "$results_an_dem/_temp_`outcome'_`year'.dta", replace
}
}
}

*Capture all numeric results (e.g. to use estimates in sys review summary figure)
use "$results_an_dem/_temp_dementia_0.dta", clear
replace outcome="dem_all"
foreach outcome in   vasc alz other_dem ns_dem dementiahes {
    append using "$results_an_dem/_temp_`outcome'_0.dta"
	replace outcome="dem_hes" if outcome=="dementia"
}
    append using "$results_an_dem/_temp_dementiadrugs_0.dta"
replace outcome="dem_drugs" if outcome=="dementia"
replace outcome="other_dem" if outcome=="other_de"
save "$results_an_dem\an_Primary_A1A2_main figure_ALLRESULTS_AandG_dementia", replace
sort cancer year model 
list
 
cd $results_an_dem

/**** GRAPHS  *********************** */
foreach year in 0 {
foreach db of  global databases {
foreach outcome in dem_all vasc alz other_dem ns_dem  dem_drugs dem_hes {
	*
	use "$results_an_dem\an_Primary_A1A2_main figure_ALLRESULTS_AandG_dementia", clear
	keep if year=="`year'"
	keep if outcome=="`outcome'"
	drop if model=="crude"
	replace model="crude" if model=="agesex_a"
	
	count
	if `r(N)'>0 {
	*Cancersite labels
	gen str1 sitelabel=""
	foreach site of global cancersites {
		qui include "$dofiles_an_dem\inc_cancersitetographtitle.do"
		replace sitelabel = "`name'" if cancersite=="`site'" & model == "crude"
		replace sitelabel = "`icd'" if cancersite=="`site'" & model == "adjusted"
		}

	*numeric version of cancersite variable with labels
	gen ycat = .
	label define cancersitelab 0 "X", replace
	local i = 1
	foreach site of global cancersites {
		replace ycat = `i' if cancersite == "`site'"
		label define cancersitelab `i' "`site'", add
		local i = `i' + 1
		}
	label values ycat cancersitelab 

	/*number observations with gap between cancers to represent separator 
	row in graphs*/
	gsort -ycat model
	gen obs = _n
	replace obs = . if mod(obs,2)==1
	replace obs = (3*obs/2) - 1
	replace obs = obs[_n+1] - 1  if obs==.
		
	keep obs ycat cancersite sitelabel hr lci uci result irboth model nfail

	/*graph column and axis headings*/
	count
	insobs 2, after(r(N))
	qui summ obs
	global headingobs = r(max) + 3
	di $headingobs
	replace obs=$headingobs if obs==. & _n==_N 
	gen siteheading = "{bf:Cancer site (ICD10)}" if obs==$headingobs
	gen irheading ="{bf:IR CS/GPC}" if obs==$headingobs
	gen hrheading ="{bf:HR (95% CI)}" if obs==$headingobs
	gen higherriskheading ="{it:(Higher}" if obs==$headingobs
	gen lowerriskheading ="{it:(Lower}" if obs==$headingobs
	replace obs=$headingobs-1 if obs==.
	
	/*individual graph headings*/
	include "$dofiles_an_dem\inc_outcometographtitle.do" /*locals for graph headings*/
	
	#delimit ;
	local outcomeletters "A dementia"
	;
	#delimit cr
	
	di "`outcome'"
	local x = strpos("`outcomeletters'", " `outcome'" ) - 1

	local name = "(" + substr("`outcomeletters'", `x', 1) + ") " + "`outcome'" 

	/*replace hrs and cis if hr is outside of 0.5 to 12 scale*/
	replace result = "" if hr <0.001
	foreach var in lci uci hr {
		replace `var' = . if hr < 0.5
		replace `var' = . if hr > 12
		}
	
	/*remove hrs where there are no lcis and / or ucis*/
	gen drop = 1 if lci == . | uci == .
	replace drop = 0 if obs == $headingobs
	replace drop = 0 if obs == $headingobs - 1
	foreach var in hr lci uci {
		replace `var' = . if drop == 1
		}
	replace result = "(*)" if drop == 1
	drop drop
	
	/* gen new variable for offscale lcis and ucis*/ 
	gen lcimin = 0.5 if lci <0.5 & hr !=.
	replace lci = 0.5 if lcimin == 0.5
	gen ucimax = 12 if uci > 12 & hr !=.
	replace uci = 12 if ucimax == 12
	
	/*label/headings positions*/
	gen irlabpos = 10
	gen hrlabpos = 30 /*location of HR estimates*/
	gen sitelabpos = 0.08  /*location of cancer site labels*/
	*note this leaves plenty of space as the graphs will be squashed when combined
	
	gen higherlabpos=2.2
	gen lowerlabpos=1.05
	
	/*otpion to only show site labels for graphs that will be on left hand side of
	combined graph*/
	gen sitelabelson = 1
	/*
	if "`outcome'" == "coronary" | "`outcome'" == "stroke" {
		replace sitelabelson = 1
		}
	*/
		
	/*KB 25/2	*/
	sort cancersite model obs
	by cancersite: replace sitelabel = sitelabel + " " + sitelabel[1] if _n==2 
	by cancersite: replace sitelabel = "[" + string(nfail) + "]" if _n==1 
	replace sitelabel = subinstr(sitelabel, "Non-Hodgkin lymphoma", "NHL ", 1)
	replace sitelabel = subinstr(sitelabel, "Multiple myeloma", "Mult myeloma ", 1)
	replace sitelabel = subinstr(sitelabel, "Malignant melanoma", "Mal melanoma ", 1)
	replace sitelabel = "[n outcomes]" if _n==1
	replace sitelabel = "" if _n==2
	replace higherriskheading ="{it:risk)}" if _n==1
	replace lowerriskheading ="{it:risk)}" if _n==1

	gen overlab = ">"
	gen underlab = "<"

	
	/*******************************************************************************
	#draw graph
	*******************************************************************************/
		
	graph twoway ///
	/// hr and cis (crude)
	|| scatter obs hr if model == "crude", msymbol(smtriangle) msize(small) mcolor(black) 		/// data points 
		xline(1, lp(solid) lw(vthin) lcolor(black))				/// add ref line
	|| rcap lci uci obs if model == "crude", horizontal lw(vthin) col(black) msize(vtiny)		/// add the CIs
	/// hr and cis (adjusted)
	|| scatter obs hr if model == "adjusted", msymbol(smsquare) msize(small) mcolor(black) 		/// data points 
		xline(1, lp(solid) lw(vthin) lcolor(black))				/// add ref line
	|| rcap lci uci obs if model == "adjusted", horizontal lw(vthin) color(black) msize(vtiny)		/// add the CIs	
	/// markers for lcis and ucis that are offscale
	|| scatter obs lcimin, mlab(underlab) mlabpos(0) mlabsize(small) mlabcolor(black) m(i) ///
	|| scatter obs ucimax, mlab(overlab) mlabpos(0) mlabsize(small) mlabcolor(black) m(i) ///
	/// add results labels
	|| scatter obs irlabpos if model == "crude", m(i)  mlab(irboth) mlabcol(black) mlabsize(tiny) mlabposition(9)  ///
	|| scatter obs hrlabpos, m(i)  mlab(result) mlabcol(black) mlabsize(tiny) mlabposition(9)  ///
	/// Headings for site labels and results
	|| scatter obs irlabpos if obs==$headingobs, m(i) mlab(irheading) mlabcol(black) mlabsize(tiny) mlabpos(9) ///
	|| scatter obs hrlabpos if obs==$headingobs, m(i) mlab(hrheading) mlabcol(black) mlabsize(tiny) mlabpos(9) ///
	|| scatter obs sitelabpos if obs==$headingobs & sitelabelson == 1, m(i) mlab(siteheading) mlabcol(black) mlabsize(tiny) mlabpos(3) ///
	|| scatter obs higherlabpos if _n==1|obs==$headingobs, m(i) mlab(higherriskheading) mlabcol(black) mlabsize(tiny) mlabpos(9) ///
	|| scatter obs lowerlabpos if _n==1|obs==$headingobs, m(i) mlab(lowerriskheading) mlabcol(black) mlabsize(tiny) mlabpos(9) ///
	/// The cancer site labels
	|| scatter obs sitelabpos if sitelabelson == 1, m(i) mlab(sitelabel) mlabcol(black) mlabsize(tiny)  ///
	/// graph options
			, legend(off)						/// turn legend off
			xtitle("HR (95% CI)", size(tiny) margin(0 2 0 0)) 		/// x-axis title - legend off
			xlab(0.5 1 2 4, labsize(tiny)) /// x-axis tick marks
			xscale(range(0.5 10) log)						///	resize x-axis
			,ylab(none) ytitle("") yscale(r(1 23) off) ysize(10)	/// y-axis no labels or title
			graphregion(color(white))			/// get rid of rubbish grey/blue around graph
			legend(order(1 3) label(1 "Stratified by age and gender matched sets") label(3 "Additionally adjusted for shared risk factors")  /// legend (1 = first plot, 3 = 3rd plot, 5 = 5th plot)
			size(tiny) rows(1) nobox region(lstyle(none) col(none) margin(zero)) bmargin(zero)) /// 
			name("`outcome'_`year'", replace)
		
	} /*if there are data*/
} /*outcomes*/
} /*years*/
}

graph combine dem_all_0, iscale(*0.9) cols(2) rows(2) ///
ysize(5) ///
/*title("Figure 1A to D: Absolute and relative risk of cardiovascular disease in cancer survivors compared to general population controls", size(tiny))*/ ///  
note("(*) too few events for estimation; </> = CI limit <0.5 or >12" "HR = hazard ratio, CI = confidence interval, IR = incidence rate per 1000 patient years, GPC = general population controls, CS = cancer survivors", size(tiny)) ///
name(combined, replace) 
graph export "$results_an_dem/an_Primary_A1A2_main_figure_dementia_year0and1.emf", replace

*Dementia types
graph combine  alz_0 vasc_0 other_dem_0 ns_dem_0, iscale(*0.9) cols(2) rows(2) ///
ysize(10) ///
/*title("Figure 1A to D: Absolute and relative risk of cardiovascular disease in cancer survivors compared to general population controls", size(tiny))*/ ///  
note("(*) too few events for estimation; </> = CI limit <0.5 or >12" "HR = hazard ratio, CI = confidence interval, IR = incidence rate per 1000 patient years, GPC = general population controls, CS = cancer survivors", size(tiny)) ///
name(combined, replace)
graph export "$results_an_dem/an_Primary_A1A2_main_figure_dementiaTYPE_year0.emf", replace

/*
graph combine  alz_1 vasc_1 other_dem_0 ns_dem_1, iscale(*0.9) cols(2) rows(2) ///
ysize(10) ///
/*title("Figure 1A to D: Absolute and relative risk of cardiovascular disease in cancer survivors compared to general population controls", size(tiny))*/ ///  
note("(*) too few events for estimation; </> = CI limit <0.5 or >12" "HR = hazard ratio, CI = confidence interval, IR = incidence rate per 1000 patient years, GPC = general population controls, CS = cancer survivors", size(tiny)) ///
name(combined, replace)
graph export "$results_an_dem/an_Primary_A1A2_main_figure_dementiaTYPE_year1.emf", replace

graph combine  dementia_0 dementia_1 dementiahes_0 dementiahes_1, iscale(*0.9) cols(2) rows(2) ///
ysize(10) ///
/*title("Figure 1A to D: Absolute and relative risk of cardiovascular disease in cancer survivors compared to general population controls", size(tiny))*/ ///  
note("(*) too few events for estimation; </> = CI limit <0.5 or >12" "HR = hazard ratio, CI = confidence interval, IR = incidence rate per 1000 patient years, GPC = general population controls, CS = cancer survivors", size(tiny)) ///
name(combined, replace)
graph export "$results_an_dem/an_Primary_A1A2_main_figure_dementiaHES.emf", replace

graph combine  dementia_0 dementia_1 drugsdementia_0 drugsdementia_1, iscale(*0.9) cols(2) rows(2) ///
ysize(10) ///
/*title("Figure 1A to D: Absolute and relative risk of cardiovascular disease in cancer survivors compared to general population controls", size(tiny))*/ ///  
note("(*) too few events for estimation; </> = CI limit <0.5 or >12" "HR = hazard ratio, CI = confidence interval, IR = incidence rate per 1000 patient years, GPC = general population controls, CS = cancer survivors", size(tiny)) ///
name(combined, replace)
graph export "$results_an_dem/an_Primary_A1A2_main_figure_dementiaDRUGS.emf", replace

/***MAIN FIGURE - A TO D
grc1leg dementia alz vasc other_dem ns_dem, iscale(*0.9) cols(2) rows(2) ///
legendfrom(dementia) position(7) ///
/*title("Figure 1A to D: Absolute and relative risk of cardiovascular disease in cancer survivors compared to general population controls", size(tiny))*/ ///  
note("(*) too few events for estimation; </> = CI limit <0.5 or >12" "HR = hazard ratio, CI = confidence interval, IR = incidence rate per 1000 patient years, GPC = general population controls, CS = cancer survivors", size(tiny)) ///
name(combined, replace)


graph dir
graph display dementia
graph display combined, ysize(8.4) margins(tiny)  /*8.4 = close to aspect ratio of A4 paper*/
graph export "$results/an_Primary_A1A2_main_figure_1AtoD_dementia.emf", replace
graph export "$results/an_Primary_A1A2_main_figure_1AtoD_dementia.pdf", replace


capture log close
