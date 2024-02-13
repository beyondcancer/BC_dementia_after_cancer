cap log close
log using "$logfiles_an_dem/cr_forest_risk_over_time.txt", replace 
********************************************************************************



********************************************************************************
* ANXIETY, DEPRESSION
********************************************************************************

use "$results_an_dem\an_Secondary_risk-over-time_cox-model-estimates_processout_dementia.dta", clear

gen displayhrci = string(hr, "%3.2f") + " (" + string(lci, "%3.2f") + "-" + string(uci, "%3.2f") + ")"

destring year, replace
gen analysis="Start of follow-up: index date" if year==0 
replace analysis="Start of follow-up: 1 year" if year==1 
replace analysis="Start of follow-up: 3 year" if year==3 
replace analysis="Start of follow-up: 5 year" if year==5 
replace analysis="Start of follow-up: 10 year" if year==10 


tab analysis, miss

sort cancer year
gen order=1 if year==0
replace order=2 if year==1
replace order=3 if year==3
replace order=4 if year==5
replace order=5 if year==10

gen graphorder = 6-order

* limit UCI to 15
gen uci_abovemax=.
replace uci_abovemax=1 if uci>6 & uci!=.
replace uci=6 if uci_abovemax==1

* limit LCI to 15
gen lci_abovemax=.
replace lci_abovemax=1 if lci<0.05 & lci!=.
replace lci=0.05 if lci_abovemax==1


replace uci=. if hr>1000
replace lci=. if hr>1000
replace displayhrci=". (.-.)" if hr>1000
replace hr=. if hr>1000



replace uci=. if hr<0.001
replace lci=. if hr<0.001
replace hr=. if hr<0.001
replace hr=. if cancer=="leu" & outcome=="suicide" & year==10
gen overlab = ">" if uci_abovemax==1


gen anxpos = 0.08 // all analysis
gen hrxpos = 7 // HR display 

replace displayhrci="[not calculated]" if displayhrci==". (.-.)"
replace displayhrci="[not calculated]" if displayhrci=="0.00 (0.00-0.00)"
replace displayhrci="[not calculated]" if displayhrci=="0.00 (0.00-.)"
replace displayhrci="[not calculated]" if displayhrci=="1.27 (0.00-.)"
********************************************************************************
* Rename variables and cancers
	/* cancer site & order */
	gen cancersite2=""
	replace cancersite2="Oral cavity (C00-06)"     if cancersite=="ora"
	replace cancersite2="Oesophageal (C15)"	 	   if cancersite=="oes"
	replace cancersite2="Stomach (C16)" 		   if cancersite=="gas"
	replace cancersite2="Colorectal (C18-20)"      if cancersite=="col"
	replace cancersite2="Liver (C22)"		  	   if cancersite=="liv"
	replace cancersite2="Pancreas (C25)"		   if cancersite=="pan"
	replace cancersite2="Lung (C34)"  		  	   if cancersite=="lun"
	replace cancersite2="Malignant melanoma (C43)" if cancersite=="mel"
	replace cancersite2="Breast (C50)" 		 	   if cancersite=="bre"
	replace cancersite2="Cervix (C53)" 		  	   if cancersite=="cer"
	replace cancersite2="Uterus (C54-55)" 	  	   if cancersite=="ute"
	replace cancersite2="Ovary (C56)" 		  	   if cancersite=="ova"
	replace cancersite2="Prostate (C61)"		   if cancersite=="pro"
	replace cancersite2="Kidney (C64)" 		  	   if cancersite=="kid"
	replace cancersite2="Bladder (C67)" 		   if cancersite=="bla" 
	replace cancersite2="CNS (C71-72)" 		  	   if cancersite=="cns"
	replace cancersite2="Thyroid (C73)" 		   if cancersite=="thy"
	replace cancersite2="NHL (C82-85)" 		  	   if cancersite=="nhl"
	replace cancersite2="Multiple myeloma (C90)"   if cancersite=="mye"
	replace cancersite2="Leukaemia (C91-95)"   	   if cancersite=="leu"


foreach cancer in "Oral cavity (C00-06)"  "Oesophageal (C15)" "Stomach (C16)" "Colorectal (C18-20)" "Liver (C22)" "Pancreas (C25)" "Lung (C34)" "Malignant melanoma (C43)" "Breast (C50)" "Cervix (C53)" "Uterus (C54-55)" "Ovary (C56)" "Prostate (C61)" "Kidney (C64)" "Bladder (C67)" "CNS (C71-72)" "Thyroid (C73)" "NHL (C82-85)" "Multiple myeloma (C90)" "Leukaemia (C91-95)" {
	
	if "`cancer'"=="Oral cavity (C00-06)" local namegraph="ora"
	if "`cancer'"=="Oesophageal (C15)" local namegraph="oes"	
	if "`cancer'"=="Stomach (C16)"  local namegraph="gas"
	if "`cancer'"=="Colorectal (C18-20)" local namegraph="col"
	if "`cancer'"=="Liver (C22)" local namegraph="liv"
	if "`cancer'"=="Pancreas (C25)" local namegraph="pan"
	if "`cancer'"=="Lung (C34)" local namegraph="lun"
	if "`cancer'"=="Malignant melanoma (C43)" local namegraph="mel"
	if "`cancer'"=="Breast (C50)" local namegraph="bre"
	if "`cancer'"=="Cervix (C53)" local namegraph="cer"
	if "`cancer'"=="Uterus (C54-55)" local namegraph="ute"
	if "`cancer'"=="Ovary (C56)" local namegraph="ova"
	if "`cancer'"=="Prostate (C61)" local namegraph="pro"
	if "`cancer'"=="Kidney (C64)" local namegraph="kid"
	if "`cancer'"=="Bladder (C67)" local namegraph="bla"
	if "`cancer'"=="CNS (C71-72)" local namegraph="cns"
	if "`cancer'"=="Thyroid (C73)" local namegraph="thy"
	if "`cancer'"=="NHL (C82-85)" local namegraph="nhl"
	if "`cancer'"=="Multiple myeloma (C90)" local namegraph="mye"
	if "`cancer'"=="Leukaemia (C91-95)" local namegraph="leu"	

	
	scatter graphorder hr if cancersite2=="`cancer'" & outcome=="dementia", mcol(black) msize(small) ///
	|| rcap lci uci graphorder if cancersite2=="`cancer'" & outcome=="dementia", hor mcol(black) lcol(black) ///
	|| scatter graphorder hrxpos if cancersite2=="`cancer'", m(i) mlab(displayhrci) mlabcol(black) mlabsize(2) ///
	|| scatter graphorder anxpos if cancersite2=="`cancer'", m(i) mlab(analysis) mlabcol(black) mlabsize(3) ///
	ylabels(none) ytitle("") xscale(log) xlab(0.5 1 2 4 8 15) ///
	xtitle("Hazard ratio & 95% CI") title("`cancer'") xline(1,lp(dash)) legend(off) ///
	name("`namegraph'", replace)

	graph play "J:\EHR-Working\Helena\bonefractures_cs\dofiles\Data_analysis\dofiles\edit_axis_sens.grec"
	graph save "$results_an_dem/`namegraph'.gph", replace
}

graph combine ora oes gas col liv pan lun mel bre cer ute ova pro kid bla cns thy nhl mye leu, col(5) iscale(0.3) imargin (1 1 1 1) ycommon graphregion(margin(l=0 r=0))
graph play "J:\EHR-Working\Helena\bonefractures_cs\dofiles\Data_analysis\dofiles\edit_genformat_allcancers.grec"

graph export "$results_an_dem/forest_riskovertime.pdf", as(pdf) name("Graph") replace
graph export "$results_an_dem/forest_riskovertime.tif", as(tif) name("Graph") replace
graph export "$results_an_dem/forest_riskovertime.emf", as(emf) name("Graph") replace
graph save $results_an_dem/forest_riskovertime, replace


log close