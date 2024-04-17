*Plot 5 yr survival and hrs


/**** GRAPHS  *********************** */

foreach db of  global databases {
foreach outcome in dem_all {
foreach year in 0 {		
	
	use "$results_an_dem\an_Primary_A1A2_main figure_ALLRESULTS_AandG_dementia", clear
	merge m:1 cancer using "C:\Users\encdhfor\London School of Hygiene and Tropical Medicine\Beyond Cancer_Group - Documents\Projects\Mental_health_cancer_survivors\results\5year_surv_cancers", nogen

	keep if outcome=="`outcome'"
	keep if year=="`year'"
	keep if model=="adjusted"

	count
	
	if `r(N)'>0 {
	*Cancersite labels
	gen str1 sitelabel=""
	foreach site of global cancersites {
		qui include "$dofiles_an_dem\inc_cancersitetographtitle.do"
		replace sitelabel = "`name'" if cancersite=="`site'" & model == "adjusted"
		*replace sitelabel = "`icd'" if cancersite=="`site'" & model == "adjusted"
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
	gsort -ycat 
	gen obs = _n
	replace obs = . if mod(obs,2)==1
	replace obs = (3*obs/2) - 1
	replace obs = obs[_n+1] - 1  if obs==.
		
	keep obs ycat cancersite sitelabel hr lci uci result irboth  nfail fiveyr_surv
	
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
	local outcomeletters "A anxiety B depression C selfharm D suicide"
	;
	#delimit cr
	
	local x = strpos("`outcomeletters'", " `outcome'" ) - 1
	local name = "(" + substr("`outcomeletters'", `x', 1) + ") " + "`name'" 
	di "`name'"
	if "`outcome'" == "hf" local name = "(G) Heart failure"
	
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
	gen irlabpos = 30
	gen hrlabpos = 120 /*location of HR estimates*/
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

	/*KB 25/2	
	sort cancersite obs
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
*/
		/*******************************************************************************
	#draw graph
	*******************************************************************************/
	*drop if model=="adjusted"
	graph twoway scatter fiveyr_surv hr, msymbol(smsquare) msize(small) mcolor(black) /// data points 
	|| scatter five hr, m(i) mlab(sitelabel) mlabcol(black) mlabsize(tiny)  ///
	/// graph options
			, legend(off)						/// turn legend off
			xtitle("HR", size(small) margin(0 2 0 0)) 		/// x-axis title - legend off
			xlab(1 2 3, labsize(tiny)) /// x-axis tick marks
			xscale(range(1 3) log)						///	resize x-axis
			,  ytitle("Five year survival (%)", size(small) margin(0 2 0 0))	/// y-axis no labels or title
			graphregion(color(white))			/// get rid of rubbish grey/blue around graph
			legend(order(1 3) label(1 "Stratified by age and gender matched sets") label(3 "Additionally adjusted for shared risk factors")  /// legend (1 = first plot, 3 = 3rd plot, 5 = 5th plot)
			size(tiny) rows(1) nobox region(lstyle(none) col(none) margin(zero)) bmargin(zero)) /// 
			name("`outcome'_`year'", replace)
	} /*if there are data*/
} /*outcomes*/
} /*years*/
}

graph export "$results_an_dem/an_fiveyrsurv_figure_dementia_year0.emf", replace



	use "$results_an_dem\an_Primary_A1A2_main figure_ALLRESULTS_AandG_dementia", clear
	merge m:1 cancer using "C:\Users\encdhfor\London School of Hygiene and Tropical Medicine\Beyond Cancer_Group - Documents\Projects\Mental_health_cancer_survivors\results\5year_surv_cancers", nogen

	keep if outcome=="dem_all"
	keep if year=="0"
	keep if model=="adjusted"	
	
	keep outcome hr five
	list
	gen loghr=log(hr)
	list
	*1 unit increase in five year survival (1% increase)  
	noi regress loghr five
	noi di 1-(exp(_b[fiveyr_surv]))
	