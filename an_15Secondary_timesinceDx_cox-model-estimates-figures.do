capture log close

log using "$logfiles_an_dem\an_Primary_A2_cox-model-figures-interactions.txt", replace

***********************************************************************************************

/*****************
EDITED KB 11/7/23
- to improve readibility of text on graph
- through chaning aspect ratio to make panels longer 
- (tweaks to ysize option in individual and combined graph)
- also changed mlabsize from 1.8 to vsmall for HR text
******************
*/
************************************************************************************

*set trace on
********************************************************************************
*** 1. FOREST PLOT BY OUTCOME: 
********************************************************************************
foreach outcome in  dementia {

clear all 
use "$results_an_dem/an_Secondary_timesinceDx_cox_processout_dementia.dta", clear
keep if outcome=="`outcome'"
*gen lci = substr(v6,1,4)
*gen uci = substr(v7,1,4)
*drop v6 v7
*rename v1 cancersite
*rename v4 hr
*rename v8 pvalue
order cancersite hr lci uci 
destring year, replace

bysort cancersite year: gen timeperiod=_n

replace cancersite="Oral cavity (C00-06)" 	  if cancersite=="ora"
replace cancersite="Oesophageal (C15)"	  	  if cancersite=="oes"
replace cancersite="Stomach (C16)" 		  	  if cancersite=="gas"
replace cancersite="Colorectal (C18-20)"  	  if cancersite=="col"
replace cancersite="Liver (C22)"		  	  if cancersite=="liv"
replace cancersite="Pancreas (C25)"		  	  if cancersite=="pan"
replace cancersite="Lung (C34)"  		  	  if cancersite=="lun"
replace cancersite="Malignant melanoma (C43)" if cancersite=="mel"
replace cancersite="Breast (C50)" 		  	  if cancersite=="bre"
replace cancersite="Cervix (C53)" 		  	  if cancersite=="cer"
drop if cancersite=="ute"
drop if cancersite=="ova"
drop if cancersite=="pro"
drop if cancersite=="kid"
drop if cancersite=="bla" 
drop if cancersite=="cns"
drop if cancersite=="thy"
drop if cancersite=="nhl"
drop if cancersite=="mye"
drop if cancersite=="leu"



gen displayhrci = ""
replace displayhrci = string(hr, "%4.2f") + " (" + string(lci, "%4.2f") + ", " + string(uci, "%4.2f") + ")"
*replace displayhrci = string(hr, "%3.2f") + " (" + lci + "-" + uci + ") " 
*replace displayhrci = string(hr, "%3.2f") + " (" + lci + "-" + uci + ", <.001" + ")" if p<0.001  & p!=.
*replace displayhrci = string(hr, "%3.2f") + " (" + lci + "-" + uci + ", 0.001" + ")" if p>0.001 & p<0.002
*replace displayhrci = string(hr, "%3.2f") + " (" + lci + "-" + uci + ", 0.002" + ")" if p>0.002 & p<0.003
*replace displayhrci = string(hr, "%3.2f") + " (" + lci + "-" + uci + ", 0.003" + ")" if p>0.003 & p<0.004
*replace displayhrci = string(hr, "%3.2f") + " (" + lci + "-" + uci + ", 0.004" + ")" if p>0.004 & p<0.005
*replace displayhrci = string(hr, "%3.2f") + " (" + lci + "-" + uci + ", 0.01" + ")" if p>0.005 & p<=0.01

foreach cancer in "Oral cavity (C00-06)"  "Oesophageal (C15)" "Stomach (C16)" "Colorectal (C18-20)" "Liver (C22)"  "Pancreas (C25)" "Lung (C34)" "Malignant melanoma (C43)"  "Breast (C50)"  "Cervix (C53)"  {
	count 
	local n=r(N)+1
	set obs `n'
	replace cancersite="`cancer'" in `n'
	replace timeperiod=0 in `n'
}
  
	gen timeperiod2=""
	replace timeperiod2=".  0-3 mo" if year==0.25 
	replace timeperiod2=".  0-6 mo" if year==0.5 
	replace timeperiod2=".  0-9 mo" if year==0.75 
	replace timeperiod2=".  0-1 yrs" if year==1
	replace timeperiod2=".  0-2 yrs" if year==2
	replace timeperiod2=".  0-5 yrs" if year==5
	replace timeperiod2=".  0-10 yrs" if year==10
	replace timeperiod2=".  0-25 yrs" if year==25

	gen graphorder = .
	replace graphorder=1  if cancersite=="Oral cavity (C00-06)"
	replace graphorder=2  if cancersite=="Oesophageal (C15)"
	replace graphorder=3  if cancersite=="Stomach (C16)"
	replace graphorder=4  if cancersite=="Colorectal (C18-20)"
	replace graphorder=5  if cancersite=="Liver (C22)" 
	replace graphorder=6  if cancersite=="Pancreas (C25)" 
	replace graphorder=7  if cancersite=="Lung (C34)" 
	replace graphorder=8  if cancersite=="Malignant melanoma (C43)" 
	replace graphorder=9  if cancersite=="Breast (C50)" 
	replace graphorder=10 if cancersite=="Cervix (C53)" 


	gsort graphorder timeperiod year

	gen n = _n
	gen graphorder2=101-n
	drop graphorder
	rename graphorder2 graphorder

	gen labelxpos = 0.15
	gen hrxpos = 20
	
	destring lci, replace
	destring uci, replace
	
	/* gen new variable for offscale lcis and ucis*/ 
	gen lcimin = 0.5 if lci <0.5 & hr !=.
	replace lci = 0.5 if lcimin == 0.5
	gen ucimax = 15 if uci > 15 & hr !=.
	replace uci = 15 if ucimax == 15
	
	replace hr=. if hr <0.5 | hr>15
	replace uci=. if hr==.
	replace lci=. if hr==.

	replace uci=0.5 if uci<0.5
		gen overlab = ">"
	gen underlab = "<"
	 
	scatter graphorder labelxpos if timeperiod==0, m(i) mlab(cancersite) mlabcol(black) mlabsize(vsmall) ///
	|| scatter graphorder labelxpos if timeperiod==1, m(i) mlab(timeperiod2) mlabcol(black) mlabsize(vsmall) ///
	|| scatter graphorder hr if timeperiod==1, mcol(black) msize(small) msymbol(D) ///
	|| rcap lci uci graphorder if timeperiod==1, hor mcol(black) lcol(black) ///
	|| scatter graphorder hrxpos if timeperiod==1, m(i) mlab(displayhrci) mlabcol(black) mlabsize(vsmall) ///
	///		
	|| scatter graphorder labelxpos if timeperiod==2, m(i)  ///
	|| scatter graphorder labelxpos if timeperiod==2, m(i) mlab(timeperiod2) mlabcol(black) mlabsize(vsmall) ///
	|| scatter graphorder hr if timeperiod==2, mcol(black) msize(small) msymbol(D) ///
	|| rcap lci uci graphorder if timeperiod==2, hor mcol(black) lcol(black) ///	
	|| scatter graphorder hrxpos if timeperiod==2, m(i) mlab(displayhrci) mlabcol(black) mlabsize(vsmall) ///
	///
	|| scatter graphorder labelxpos if timeperiod==3, m(i)   ///
	|| scatter graphorder labelxpos if timeperiod==3, m(i) mlab(timeperiod2) mlabcol(black) mlabsize(vsmall) ///
	|| scatter graphorder hr if timeperiod==3, mcol(black) msize(small) msymbol(D) ///
	|| rcap lci uci graphorder if timeperiod==3, hor mcol(black) lcol(black) ///	
	|| scatter graphorder hrxpos if timeperiod==3, m(i) mlab(displayhrci) mlabcol(black) mlabsize(vsmall) ///
	///
	ylabels(none) ytitle("") xscale(log range(50)) xlab(0.5 1 2 4 6) ///
	xtitle("Hazard ratio & 95% CI") xline(1,lp(dash)) legend(off) ///
	ysize(10) graphregion(color(white))
		
		

graph play "J:\EHR-Working\Helena\bonefractures_cs\dofiles\Data_analysis\dofiles\edit_axis.grec"
graph save "$results_an_dem/forest_`outcome'_timesincedx_A", replace
graph export "$results_an_dem\forest_`outcome'_timesincedx_A.emf", as(emf) name("Graph") replace
}

foreach outcome in  dementia {

clear all 
use "$results_an_dem/an_Secondary_timesinceDx_cox_processout_dementia.dta", clear
keep if outcome=="`outcome'"
*gen lci = substr(v6,1,4)
*gen uci = substr(v7,1,4)
*drop v6 v7
*rename v1 cancersite
*rename v4 hr
*rename v8 pvalue
order cancersite hr lci uci 
destring year, replace

bysort cancersite year: gen timeperiod=_n

drop if cancersite=="ora"
drop if cancersite=="oes"
drop if cancersite=="gas"
drop if cancersite=="col"
drop if cancersite=="liv"
drop if cancersite=="pan"
drop if cancersite=="lun"
drop if cancersite=="mel"
drop if cancersite=="bre"
drop if cancersite=="cer"
replace cancersite="Uterus (C54-55)" 	  	  if cancersite=="ute"
replace cancersite="Ovary (C56)" 		  	  if cancersite=="ova"
replace cancersite="Prostate (C61)"		  	  if cancersite=="pro"
replace cancersite="Kidney (C64)" 		  	  if cancersite=="kid"
replace cancersite="Bladder (C67)" 		  	  if cancersite=="bla" 
replace cancersite="CNS (C71-72)" 		  	  if cancersite=="cns"
replace cancersite="Thyroid (C73)" 		  	  if cancersite=="thy"
replace cancersite="NHL (C82-85)" 		  	  if cancersite=="nhl"
replace cancersite="Multiple myeloma (C90)"   if cancersite=="mye"
replace cancersite="Leukaemia (C91-95)"   	  if cancersite=="leu"



gen displayhrci = ""
replace displayhrci = string(hr, "%4.2f") + " (" + string(lci, "%4.2f") + ", " + string(uci, "%4.2f") + ")"
*replace displayhrci = string(hr, "%3.2f") + " (" + lci + "-" + uci + ") " 
*replace displayhrci = string(hr, "%3.2f") + " (" + lci + "-" + uci + ", <.001" + ")" if p<0.001  & p!=.
*replace displayhrci = string(hr, "%3.2f") + " (" + lci + "-" + uci + ", 0.001" + ")" if p>0.001 & p<0.002
*replace displayhrci = string(hr, "%3.2f") + " (" + lci + "-" + uci + ", 0.002" + ")" if p>0.002 & p<0.003
*replace displayhrci = string(hr, "%3.2f") + " (" + lci + "-" + uci + ", 0.003" + ")" if p>0.003 & p<0.004
*replace displayhrci = string(hr, "%3.2f") + " (" + lci + "-" + uci + ", 0.004" + ")" if p>0.004 & p<0.005
*replace displayhrci = string(hr, "%3.2f") + " (" + lci + "-" + uci + ", 0.01" + ")" if p>0.005 & p<=0.01

foreach cancer in  "Uterus (C54-55)"  "Ovary (C56)"  "Prostate (C61)" "Kidney (C64)"  "Bladder (C67)" "CNS (C71-72)" "Thyroid (C73)" "NHL (C82-85)" "Multiple myeloma (C90)" "Leukaemia (C91-95)" {
	count 
	local n=r(N)+1
	set obs `n'
	replace cancersite="`cancer'" in `n'
	replace timeperiod=0 in `n'
}
  
	gen timeperiod2=""
	replace timeperiod2=".  0-3 mo" if year==0.25 
	replace timeperiod2=".  0-6 mo" if year==0.5 
	replace timeperiod2=".  0-9 mo" if year==0.75 
	replace timeperiod2=".  0-1 yrs" if year==1
	replace timeperiod2=".  0-2 yrs" if year==2
	replace timeperiod2=".  0-5 yrs" if year==5
	replace timeperiod2=".  0-10 yrs" if year==10
	replace timeperiod2=".  0-25 yrs" if year==25

	gen graphorder = .
	replace graphorder=1 if cancersite=="Uterus (C54-55)" 
	replace graphorder=2 if cancersite=="Ovary (C56)" 
	replace graphorder=3 if cancersite=="Prostate (C61)" 
	replace graphorder=4 if cancersite=="Kidney (C64)" 
	replace graphorder=5 if cancersite=="Bladder (C67)"
	replace graphorder=6 if cancersite=="CNS (C71-72)" 
	replace graphorder=7 if cancersite=="Thyroid (C73)"
	replace graphorder=8 if cancersite=="NHL (C82-85)" 
	replace graphorder=9 if cancersite=="Multiple myeloma (C90)" 
	replace graphorder=10 if cancersite=="Leukaemia (C91-95)"


	gsort graphorder timeperiod year

	gen n = _n
	gen graphorder2=101-n
	drop graphorder
	rename graphorder2 graphorder

	gen labelxpos = 0.15
	gen hrxpos = 20
	
	destring lci, replace
	destring uci, replace
	
	/* gen new variable for offscale lcis and ucis*/ 
	gen lcimin = 0.5 if lci <0.5 & hr !=.
	replace lci = 0.5 if lcimin == 0.5
	gen ucimax = 15 if uci > 15 & hr !=.
	replace uci = 15 if ucimax == 15
	
	replace hr=. if hr <0.5 | hr>15
	replace uci=. if hr==.
	replace lci=. if hr==.

	replace uci=0.5 if uci<0.5
		gen overlab = ">"
	gen underlab = "<"
	 
	scatter graphorder labelxpos if timeperiod==0, m(i) mlab(cancersite) mlabcol(black) mlabsize(vsmall) ///
	|| scatter graphorder labelxpos if timeperiod==1, m(i) mlab(timeperiod2) mlabcol(black) mlabsize(vsmall) ///
	|| scatter graphorder hr if timeperiod==1, mcol(black) msize(small) msymbol(D) ///
	|| rcap lci uci graphorder if timeperiod==1, hor mcol(black) lcol(black) ///
	|| scatter graphorder hrxpos if timeperiod==1, m(i) mlab(displayhrci) mlabcol(black) mlabsize(vsmall) ///
	///		
	|| scatter graphorder labelxpos if timeperiod==2, m(i)  ///
	|| scatter graphorder labelxpos if timeperiod==2, m(i) mlab(timeperiod2) mlabcol(black) mlabsize(vsmall) ///
	|| scatter graphorder hr if timeperiod==2, mcol(black) msize(small) msymbol(D) ///
	|| rcap lci uci graphorder if timeperiod==2, hor mcol(black) lcol(black) ///	
	|| scatter graphorder hrxpos if timeperiod==2, m(i) mlab(displayhrci) mlabcol(black) mlabsize(vsmall) ///
	///
	|| scatter graphorder labelxpos if timeperiod==3, m(i)   ///
	|| scatter graphorder labelxpos if timeperiod==3, m(i) mlab(timeperiod2) mlabcol(black) mlabsize(vsmall) ///
	|| scatter graphorder hr if timeperiod==3, mcol(black) msize(small) msymbol(D) ///
	|| rcap lci uci graphorder if timeperiod==3, hor mcol(black) lcol(black) ///	
	|| scatter graphorder hrxpos if timeperiod==3, m(i) mlab(displayhrci) mlabcol(black) mlabsize(vsmall) ///
	///
	ylabels(none) ytitle("") xscale(log range(50)) xlab(0.5 1 2 4 6) ///
	xtitle("Hazard ratio & 95% CI") xline(1,lp(dash)) legend(off) ///
	ysize(10) graphregion(color(white))
		
		

graph play "J:\EHR-Working\Helena\bonefractures_cs\dofiles\Data_analysis\dofiles\edit_axis.grec"
graph save "$results_an_dem/forest_`outcome'_timesincedx_B", replace
graph export "$results_an_dem\forest_`outcome'_timesincedx_B.emf", as(emf) name("Graph") replace
} 

/*********************************************************************************
*** COMBINE FOREST PLOTS
	graph combine ///
			$results/forest_depression_timesincedx.gph /// 
			$results/forest_anxiety_timesincedx.gph ///
			, col(2) iscale(0.6) imargin (0 0 0 0) graphregion(margin(l=0 r=0) color(white)) plotregion(color(white)) ysize(7)
			graph save "$results/Forest_timesincedx_anxdep.gph", replace
			graph export "$results\Forest_timesincedx_anxdep.emf", as(emf) name("Graph") replace

	graph combine ///
			$results/forest_selfharm_timesincedx.gph ///
			$results/forest_suicide_timesincedx.gph ///	
			, col(2) iscale(0.6) imargin (0 0 0 0) graphregion(margin(l=0 r=0) color(white)) plotregion(color(white)) ysize(7)
			graph save "$results/Forest_timesincedx_SHsuic.gph", replace
			graph export "$results\Forest_timesincedx_SHsuic.emf", as(emf) name("Graph") replace			
************************************************************************************
log close




/* 20-panel figures for the appendix
***********************************************************************************************
foreach db of  global databases {
    *
foreach outcome in depression anxiety selfharm suicide {
foreach cancer of global cancersites { 

if "`cancer'"=="col" local cancerlong "Colorectal (C18-20)"
if "`cancer'"=="lun" local cancerlong "Lung (C34)"
if "`cancer'"=="mel" local cancerlong "Malignant Melanoma (C43)"
if "`cancer'"=="bre" local cancerlong "Breast (C50)"
if "`cancer'"=="ute" local cancerlong "Uterus (C54-55)"
if "`cancer'"=="pro" local cancerlong "Prostate (C61)"
if "`cancer'"=="bla" local cancerlong "Bladder (C67)"
if "`cancer'"=="nhl" local cancerlong "Non-Hodgkin Lymphoma (C82-85)"
if "`cancer'"=="leu" local cancerlong "Leukaemia (C91-95)" 
if "`cancer'"=="ora" local cancerlong "Oral cavity (C00-06)" 
if "`cancer'"=="oes" local cancerlong "Oesophageal (C15)" 
if "`cancer'"=="gas" local cancerlong "Stomach (C16)" 
if "`cancer'"=="liv" local cancerlong "Liver (C22)" 
if "`cancer'"=="pan" local cancerlong "Pancreas (C25)" 
if "`cancer'"=="cer" local cancerlong "Cervix (C53)" 
if "`cancer'"=="ova" local cancerlong "Ovary (C56)" 
if "`cancer'"=="kid" local cancerlong "Kidney (C64)" 
if "`cancer'"=="cns" local cancerlong "CNS (C71-72)" 
if "`cancer'"=="thy" local cancerlong "Thyroid (C73)" 
if "`cancer'"=="mye" local cancerlong "Multiple myeloma (C90)" 


use "$results/an_Secondary_timesinceDx_cox_processout.dta", clear
list in 1/10
keep if outcome=="`outcome'"
destring year, replace 
gen year_text=""
replace year_text = "0-1y since diagnosis" if year == 1
replace year_text = "0-2y since diagnosis" if  year == 2
replace year_text = "0-5y since diagnosis" if year == 5 
replace year_text = "0-10y since diagnosis" if  year == 10 

list 
gen esthr = string(hr, "%4.2f") + " (" + string(lci, "%4.2f") + ", " + string(uci, "%4.2f") + ")"

gen n=_n

gen stratumx = 0.01
gen estx = 30	
gen px = 500

	/* gen new variable for offscale lcis and ucis*/ 
	gen lcimin = 0.5 if lci <0.5 & hr !=.
	replace lci = 0.5 if lcimin == 0.5
	gen ucimax = 15 if uci > 15 & hr !=.
	replace uci = 15 if ucimax == 15
	
	replace hr=. if hr <0.5 | hr>15
	replace uci=0.5 if uci<0.5
		gen overlab = ">"
	gen underlab = "<"

scatter n hr , mcol(black) ///
	|| scatter n stratumx, m(i) mlab(year_text) mlabcol(black) ///
	|| rcap uci lci n, hor lc(black) ///
	|| scatter n estx, m(i) mlab(esthr) mlabcol(black) ///
	|| scatter n lcimin, mlab(underlab) mlabpos(0) mlabsize(small) mlabcolor(black) m(i) ///
	|| scatter n ucimax, mlab(overlab) mlabpos(0) mlabsize(small) mlabcolor(black) m(i) ///
	|| , xscale(range (0.06 1500) log) xlab(0.5 1 2 4 8 20) yscale(range(26)) ///
	ylab(none) xtitle("HR and 95% CI") ytitle("") legend(off) title("`cancerlong'") ///
	name(`cancer', replace) xline(1, lp(dash))
	
graph save "$results/`cancer'.gph", replace


/*Re do selected graphs for main paper, with more expansive titles
if (("`outcome'"=="vte" & ("`cancer'"=="bre"|"`cancer'"=="col"))|("`outcome'"=="hfcardiomyopathy" & "`cancer'"=="nhl")) {
	if "`outcome'"=="vte" local outcomelong "Venous thromboembolism"
	if "`outcome'"=="hfcardiomyopathy" local outcomelong "Heart failure/cardiomyopathy"
	if "`cancer'"=="bre" local cancerlong2 "breast cancer"
	if "`cancer'"=="col" local cancerlong2 "colorectal cancer"
	if "`cancer'"=="nhl" local cancerlong2 "non-Hodgkin lymphoma"
	scatter n hr , mcol(black) ///
		|| scatter n interacx, m(i) mlab(stratum) mlabcol(black) ///
		|| rcap uci lci n, hor lc(black) ///
		|| scatter n estx, m(i) mlab(esthr) mlabcol(black) ///
		|| scatter n px if pint<., m(i) mlab(pintstr) mlabcol(black) ///
		|| , xscale(range (0.06 1024) log) xlab(0.5 1 2 4 8) yscale(range(26)) ylab(none) xtitle("HR and 95% CI") ytitle("") legend(off) title("`outcomelong' risk after `cancerlong2'", size(medium)) name(`cancer', replace) xline(1, lp(dash))
	graph save "$results/`cancer'_`outcome'_`db'", replace
	}
*/
} /*outcome*/
graph combine $cancersites, altshrink rows(3)
graph export "$results\an_Primary_A2_cox-model-figures-interactions_Appendixfig_`outcome'_`db'.tif", width(8000) height(6000) replace
graph export "$results\an_Primary_A2_cox-model-figures-interactions_Appendixfig_`outcome'_`db'.emf", replace
graph export "$results\an_Primary_A2_cox-model-figures-interactions_Appendixfig_`outcome'_`db'.jpg", replace

graph drop _all
} /*cancer*/
} /*db*/


/*
graph combine "$results/nhl_hfcardiomyopathy" "$results/bre_vte" "$results/col_vte" , altshrink cols(1) ysize(10)
graph export "$results/an_Primary_A2_cox-model-figures-interactions_figure2.emf", replace
graph export "$results/an_Primary_A2_cox-model-figures-interactions_figure2.pdf", replace

erase "$results/nhl_hfcardiomyopathy.gph"
erase "$results/bre_vte.gph"
erase "$results/col_vte.gph"


capture log close
