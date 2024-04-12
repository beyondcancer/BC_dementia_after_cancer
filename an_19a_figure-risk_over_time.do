capture log close

log using "$logfiles_an_dem\an_19a_figure-risk_over_time.txt", replace

***********************************************************************************************
************************************************************************************

*set trace on
********************************************************************************
*** 1. FOREST PLOT BY OUTCOME: 
********************************************************************************

clear all 
use "$results_an_dem\an_Secondary_risk-over-time_cox-model-estimates_processout_dementia.dta", clear

order cancersite hr lci uci 

destring year, replace
gen year2="Index date" if year==0 
replace year2="1 year" if year==1 
replace year2="3 year" if year==3 
replace year2="5 year" if year==5 
replace year2="10 year" if year==10 
keep if outcome=="dementia"
*drop if year==5 | year==10
bysort cancersite (year): gen year_n=_n

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
replace displayhrci="(not calculated)" if uci==. | beta==0 | sebeta==0

*replace displayhrci = string(hr, "%3.2f") + " (" + lci + "-" + uci + ") " 
*replace displayhrci = string(hr, "%3.2f") + " (" + lci + "-" + uci + ", <.001" + ")" if p<0.001  & p!=.
*replace displayhrci = string(hr, "%3.2f") + " (" + lci + "-" + uci + ", 0.001" + ")" if p>0.001 & p<0.002
*replace displayhrci = string(hr, "%3.2f") + " (" + lci + "-" + uci + ", 0.002" + ")" if p>0.002 & p<0.003
*replace displayhrci = string(hr, "%3.2f") + " (" + lci + "-" + uci + ", 0.003" + ")" if p>0.003 & p<0.004
*replace displayhrci = string(hr, "%3.2f") + " (" + lci + "-" + uci + ", 0.004" + ")" if p>0.004 & p<0.005
*replace displayhrci = string(hr, "%3.2f") + " (" + lci + "-" + uci + ", 0.01" + ")" if p>0.005 & p<=0.01

foreach cancer in "Oral cavity (C00-06)"  "Oesophageal (C15)" "Stomach (C16)" "Colorectal (C18-20)" "Liver (C22)"  "Pancreas (C25)" "Lung (C34)" "Malignant melanoma (C43)"  "Breast (C50)"  "Cervix (C53)"  "Uterus (C54-55)"  "Ovary (C56)"  "Prostate (C61)" "Kidney (C64)"  "Bladder (C67)" "CNS (C71-72)" "Thyroid (C73)" "NHL (C82-85)" "Multiple myeloma (C90)" "Leukaemia (C91-95)" {
	count 
	local n=r(N)+1
	set obs `n'
	replace cancersite="`cancer'" in `n'
	replace year=-1 in `n'
}
  
	
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
	replace graphorder=11 if cancersite=="Uterus (C54-55)" 
	replace graphorder=12 if cancersite=="Ovary (C56)" 
	replace graphorder=13 if cancersite=="Prostate (C61)" 
	replace graphorder=14 if cancersite=="Kidney (C64)" 
	replace graphorder=15 if cancersite=="Bladder (C67)"
	replace graphorder=16 if cancersite=="CNS (C71-72)" 
	replace graphorder=17 if cancersite=="Thyroid (C73)"
	replace graphorder=18 if cancersite=="NHL (C82-85)" 
	replace graphorder=19 if cancersite=="Multiple myeloma (C90)" 
	replace graphorder=20 if cancersite=="Leukaemia (C91-95)"

	*replace year=-1 if year==0 & display==""

	gsort graphorder year year_n

	gen n = _n
	gen graphorder2=101-n
	drop graphorder
	rename graphorder2 graphorder

	gen labelxpos = 0.15
	gen hrxpos = 10

	
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
	
	foreach var in hr uci lci {
		replace `var'=. if displayhrci=="(not calculated)"
	}
	
	 
	scatter graphorder labelxpos if display=="", m(i) mlab(cancersite) mlabcol(black) mlabsize(vsmall) ///
	|| scatter graphorder labelxpos if year==0, m(i) mlab(year2) mlabcol(black) mlabsize(vsmall) ///
	|| scatter graphorder hr if year==0, mcol(black) msize(vsmall) msymbol(D) ///
	|| rcap lci uci graphorder if year==0, hor mcol(black) lcol(black) ///
	|| scatter graphorder hrxpos if year==0, m(i) mlab(displayhrci) mlabcol(black) mlabsize(vsmall) ///
	///	
	|| scatter graphorder labelxpos if year==1, m(i) mlab(year2) mlabcol(black) mlabsize(vsmall) ///
	|| scatter graphorder hr if year==1, mcol(black) msize(vsmall) msymbol(D) ///
	|| rcap lci uci graphorder if year==1, hor mcol(black) lcol(black) ///
	|| scatter graphorder hrxpos if year==1, m(i) mlab(displayhrci) mlabcol(black) mlabsize(vsmall) ///
	///		
	|| scatter graphorder labelxpos if year==3, m(i)  ///
	|| scatter graphorder labelxpos if year==3, m(i) mlab(year2) mlabcol(black) mlabsize(vsmall) ///
	|| scatter graphorder hr if year==3, mcol(black) msize(vsmall) msymbol(D) ///
	|| rcap lci uci graphorder if year==3, hor mcol(black) lcol(black) ///	
	|| scatter graphorder hrxpos if year==3, m(i) mlab(displayhrci) mlabcol(black) mlabsize(vsmall) ///
	///
	|| scatter graphorder labelxpos if year==5, m(i)   ///
	|| scatter graphorder labelxpos if year==5, m(i) mlab(year2) mlabcol(black) mlabsize(vsmall) ///
	|| scatter graphorder hr if year==5, mcol(black) msize(vsmall) msymbol(D) ///
	|| rcap lci uci graphorder if year==5, hor mcol(black) lcol(black) ///	
	|| scatter graphorder hrxpos if year==5, m(i) mlab(displayhrci) mlabcol(black) mlabsize(vsmall) ///
	///
	|| scatter graphorder labelxpos if year==10, m(i)   ///
	|| scatter graphorder labelxpos if year==10, m(i) mlab(year2) mlabcol(black) mlabsize(vsmall) ///
	|| scatter graphorder hr if year==10, mcol(black) msize(vsmall) msymbol(D) ///
	|| rcap lci uci graphorder if year==10, hor mcol(black) lcol(black) ///	
	|| scatter graphorder hrxpos if year==10, m(i) mlab(displayhrci) mlabcol(black) mlabsize(vsmall) ///
	ylabels(none) ytitle("") xscale(log range(30)) xlab(0.5 1 2 4 6) ///
	xtitle("Hazard ratio & 95% CI") xline(1,lp(dash)) legend(off) ///
	ysize(15) graphregion(color(white))
		
		

graph play "J:\EHR-Working\Helena\bonefractures_cs\dofiles\Data_analysis\dofiles\edit_axis.grec"
graph save "$results_an_dem/forest_dementia_year", replace
graph export "$results_an_dem\forest_dementia_year.emf", as(emf) name("Graph") replace


