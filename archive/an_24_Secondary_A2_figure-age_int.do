capture log close

log using "$logfiles_an_dem\an_Primary_A2_cox-model-figures-age.txt", replace

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
capture log close

log using "$logfiles_an_dem/an_Primary_A2_cox-model-figures-age.txt", replace

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


clear all 
use "$results_an_dem/an_Primary_A2_cox-model-estimates_int_processout_aandg_dementia.dta", clear
keep if intvar=="age_cat"
replace level=1 if level==0
order cancer hr lci uci 

bysort cancer (level): gen age_n=_n

replace cancer="Oral cavity (C00-06)" 	  if cancer=="ora"
replace cancer="Oesophageal (C15)"	  	  if cancer=="oes"
replace cancer="Stomach (C16)" 		  	  if cancer=="gas"
replace cancer="Colorectal (C18-20)"  	  if cancer=="col"
replace cancer="Liver (C22)"		  	  if cancer=="liv"
replace cancer="Pancreas (C25)"		  	  if cancer=="pan"
replace cancer="Lung (C34)"  		  	  if cancer=="lun"
replace cancer="Malignant melanoma (C43)" if cancer=="mel"
replace cancer="Breast (C50)" 		  	  if cancer=="bre"
replace cancer="Cervix (C53)" 		  	  if cancer=="cer"
replace cancer="Uterus (C54-55)" 	  	  if cancer=="ute"
replace cancer="Ovary (C56)" 		  	  if cancer=="ova"
replace cancer="Prostate (C61)"		  	  if cancer=="pro"
replace cancer="Kidney (C64)" 		  	  if cancer=="kid"
replace cancer="Bladder (C67)" 		  	  if cancer=="bla" 
replace cancer="CNS (C71-72)" 		  	  if cancer=="cns"
replace cancer="Thyroid (C73)" 		  	  if cancer=="thy"
replace cancer="NHL (C82-85)" 		  	  if cancer=="nhl"
replace cancer="Multiple myeloma (C90)"   if cancer=="mye"
replace cancer="Leukaemia (C91-95)"   	  if cancer=="leu"



gen displayhrci = ""
replace displayhrci = string(hr, "%4.2f") + " (" + string(lci, "%4.2f") + ", " + string(uci, "%4.2f") + ")"

foreach cancer in "Oral cavity (C00-06)"  "Oesophageal (C15)" "Stomach (C16)" "Colorectal (C18-20)" "Liver (C22)"  "Pancreas (C25)" "Lung (C34)" "Malignant melanoma (C43)"  "Breast (C50)"  "Cervix (C53)"  "Uterus (C54-55)"  "Ovary (C56)"  "Prostate (C61)" "Kidney (C64)"  "Bladder (C67)" "CNS (C71-72)" "Thyroid (C73)" "NHL (C82-85)" "Multiple myeloma (C90)" "Leukaemia (C91-95)" {
	count 
	local n=r(N)+1
	set obs `n'
	replace cancer="`cancer'" in `n'
	replace level=0 in `n'
}
  
	gen age2=""
	replace age2=".  18-64 years" if level==1
	replace age2=".  65-79" if level==2
	replace age2=".   ≥80 years" if level==3
	
	gen graphorder = .
	replace graphorder=1  if cancer=="Oral cavity (C00-06)"
	replace graphorder=2  if cancer=="Oesophageal (C15)"
	replace graphorder=3  if cancer=="Stomach (C16)"
	replace graphorder=4  if cancer=="Colorectal (C18-20)"
	replace graphorder=5  if cancer=="Liver (C22)" 
	replace graphorder=6  if cancer=="Pancreas (C25)" 
	replace graphorder=7  if cancer=="Lung (C34)" 
	replace graphorder=8  if cancer=="Malignant melanoma (C43)" 
	replace graphorder=9  if cancer=="Breast (C50)" 
	replace graphorder=10 if cancer=="Cervix (C53)" 
	replace graphorder=11 if cancer=="Uterus (C54-55)" 
	replace graphorder=12 if cancer=="Ovary (C56)" 
	replace graphorder=13 if cancer=="Prostate (C61)" 
	replace graphorder=14 if cancer=="Kidney (C64)" 
	replace graphorder=15 if cancer=="Bladder (C67)"
	replace graphorder=16 if cancer=="CNS (C71-72)" 
	replace graphorder=17 if cancer=="Thyroid (C73)"
	replace graphorder=18 if cancer=="NHL (C82-85)" 
	replace graphorder=19 if cancer=="Multiple myeloma (C90)" 
	replace graphorder=20 if cancer=="Leukaemia (C91-95)"


	gsort graphorder level age_n

	gen n = _n
	gen graphorder2=101-n
	drop graphorder
	rename graphorder2 graphorder

	gen labelxpos = 0.15
	gen hrxpos = 16

	
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
	 
	scatter graphorder labelxpos if level==0, m(i) mlab(cancer) mlabcol(black) mlabsize(vsmall) ///
	|| scatter graphorder labelxpos if level==1, m(i) mlab(age2) mlabcol(black) mlabsize(vsmall) ///
	|| scatter graphorder hr if level==1, mcol(black) msize(vsmall) msymbol(D) ///
	|| rcap lci uci graphorder if level==1, hor mcol(black) lcol(black) ///
	|| scatter graphorder hrxpos if level==1, m(i) mlab(displayhrci) mlabcol(black) mlabsize(vsmall) ///
	///		
	|| scatter graphorder labelxpos if level==2, m(i) mlab(age2) mlabcol(black) mlabsize(vsmall) ///
	|| scatter graphorder hr if level==2, mcol(black) msize(vsmall) msymbol(D) ///
	|| rcap lci uci graphorder if level==2, hor mcol(black) lcol(black) ///	
	|| scatter graphorder hrxpos if level==2, m(i) mlab(displayhrci) mlabcol(black) mlabsize(vsmall) ///
	///
	|| scatter graphorder labelxpos if level==3, m(i) mlab(age2) mlabcol(black) mlabsize(vsmall) ///
	|| scatter graphorder hr if level==3, mcol(black) msize(vsmall) msymbol(D) ///
	|| rcap lci uci graphorder if level==3, hor mcol(black) lcol(black) ///	
	|| scatter graphorder hrxpos if level==3, m(i) mlab(displayhrci) mlabcol(black) mlabsize(vsmall) ///
	///
	|| scatter graphorder labelxpos if level==4, m(i) mlab(age2) mlabcol(black) mlabsize(vsmall) ///
	|| scatter graphorder hr if level==4, mcol(black) msize(vsmall) msymbol(D) ///
	|| rcap lci uci graphorder if level==4, hor mcol(black) lcol(black) ///	
	|| scatter graphorder hrxpos if level==4, m(i) mlab(displayhrci) mlabcol(black) mlabsize(vsmall) ///
	ylabels(none) ytitle("") xscale(log range(50)) xlab(0.5 1 2 4 6) ///
	xtitle("Hazard ratio & 95% CI") xline(1,lp(dash)) legend(off) ///
	ysize(10) graphregion(color(white))
		
		

graph play "J:\EHR-Working\Helena\bonefractures_cs\dofiles\Data_analysis\dofiles\edit_axis.grec"
graph save "$results_an_dem/forest_`outcome'_age", replace
graph export "$results_an_dem\forest_`outcome'_age.emf", as(emf) name("Graph") replace
}


