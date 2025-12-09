capture log close

log using "$logfiles_an_dem\an_Primary_A2_cox-model-figures-stage.txt", replace

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

cap file close tablecontent
file open tablecontent using "$results_an_dem\Table_numbers_cancers_stage.txt", write text replace

***********************************************************************************************

foreach site of global cancersites {
foreach db in aandg {
use "$datafiles_an_dem/cr_dataforDEManalysis_`db'_`site'.dta", clear 

keep if cancer=="`site'"
local outcome dementia
local year 0
count
recode smokstatus 12=3
drop if h_odementia==1

	include "$dofiles_an_dem/inc_excludepriorandset_dementia.do" /*excludes prior specific outcomes and st sets data*/

	
	
*Generate stage_binary
	if "`site'"=="cns" {
	local stage grade_cns
	}
	if "`site'"=="leu" {
	local stage stage_leu
	}
	if "`site'"=="nhl" {
	local stage stage_nhl
	}
	if "`site'"=="mye" {
	local stage stage_mye
	}
	if "`site'"=="bre" | "`site'"=="ova" | "`site'"=="bla" | "`site'"=="bre" | "`site'"=="cer" | "`site'"=="col" | "`site'"=="gas" | "`site'"=="kid" | "`site'"=="liv" | "`site'"=="lun" | "`site'"=="mel" | "`site'"=="oes" | "`site'"=="ora" | "`site'"=="ova" | "`site'"=="pan" | "`site'"=="pro" | "`site'"=="thy" | "`site'"=="ute" {
	local stage stage_tnm
	}
	
	gen stage_final=`stage'
	recode stage_final 2=1 3=2 4=2
	replace stage_final=0 if  exposed==0
	replace stage_final=9 if stage_final==99 & exposed==1
	replace stage_final=9 if stage_final==. & exposed==1 
	replace stage_final=. if doentry<=d(01jan2013)
	tab stage_final
	tab stage_final, nolab

*Stage
 count  if exposed == 1 & stage_final!=.
 local tot=r(N)
 count  if exposed == 1 & stage_final==1
 local s1=r(N)
 local s1_p=(`s1'/`tot')*100
  count  if exposed == 1 & stage_final==2
 local s2=r(N)
  local s2_p=(`s2'/`tot')*100

  count  if exposed == 1 & stage_final==9
 local s9=r(N)
   local sm_p=(`s9'/`tot')*100
   di "`s1_p'"
  	file write tablecontent "cancer" _tab "stage" _tab "nevents" _n
  foreach stage in 1 2 9 {
  	file write tablecontent "`site'" _tab "`stage'" _tab (`s`stage'') _n

  }
}
}

file close tablecontent

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
*** 1. FOREST PLOT OF STAGE: 
********************************************************************************
import delimited "J:\EHR-Working\Krishnan\20_000268\results\dementia\Table_numbers_cancers_stage.txt", varnames(1) clear 
drop if cancer=="cancer"
rename cancer cancersite
merge 1:1 cancersite stage using "$results_an_dem/an_Primary_A2_cox-model-estimates_processout_stage.dta"

drop if cancersite=="liv" | cancersite=="cns" | cancersite=="mye" | cancersite=="leu"

order cancersite hr lci uci 
destring stage, replace

bysort cancersite (stage): gen stage_n=_n

replace cancersite="Oral cavity (C00-06)" 	  if cancersite=="ora"
replace cancersite="Oesophageal (C15)"	  	  if cancersite=="oes"
replace cancersite="Stomach (C16)" 		  	  if cancersite=="gas"
replace cancersite="Colorectal (C18-20)"  	  if cancersite=="col"
*replace cancersite="Liver (C22)"		  	  if cancersite=="liv"
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
*replace cancersite="CNS (C71-72)" 		  	  if cancersite=="cns"
replace cancersite="Thyroid (C73)" 		  	  if cancersite=="thy"
replace cancersite="NHL (C82-85)" 		  	  if cancersite=="nhl"
*replace cancersite="Multiple myeloma (C90)"   if cancersite=="mye"
*replace cancersite="Leukaemia (C91-95)"   	  if cancersite=="leu"



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


*"Liver (C22)""CNS (C71-72)"  "Multiple myeloma (C90)" "Leukaemia (C91-95)" 
foreach cancer in "Oral cavity (C00-06)"  "Oesophageal (C15)" "Stomach (C16)" "Colorectal (C18-20)"   "Pancreas (C25)" "Lung (C34)" "Malignant melanoma (C43)"  "Breast (C50)"  "Cervix (C53)"  "Uterus (C54-55)"  "Ovary (C56)"  "Prostate (C61)" "Kidney (C64)"  "Bladder (C67)" "Thyroid (C73)" "NHL (C82-85)"{
	count 
	local n=r(N)+1
	set obs `n'
	replace cancersite="`cancer'" in `n'
	replace stage=0 in `n'
}
  
	gen stage2=""
	replace stage2=".  Early" if stage==1
	replace stage2=".  Late" if stage==2
	replace stage2=".  Missing stage" if stage==9 
	
	
	gen graphorder = .
	replace graphorder=1  if cancersite=="Oral cavity (C00-06)"
	replace graphorder=2  if cancersite=="Oesophageal (C15)"
	replace graphorder=3  if cancersite=="Stomach (C16)"
	replace graphorder=4  if cancersite=="Colorectal (C18-20)"
	*replace graphorder=5  if cancersite=="Liver (C22)" 
	replace graphorder=5  if cancersite=="Pancreas (C25)" 
	replace graphorder=6  if cancersite=="Lung (C34)" 
	replace graphorder=7  if cancersite=="Malignant melanoma (C43)" 
	replace graphorder=8  if cancersite=="Breast (C50)" 
	replace graphorder=9 if cancersite=="Cervix (C53)" 
	replace graphorder=10 if cancersite=="Uterus (C54-55)" 
	replace graphorder=11 if cancersite=="Ovary (C56)" 
	replace graphorder=12 if cancersite=="Prostate (C61)" 
	replace graphorder=13 if cancersite=="Kidney (C64)" 
	replace graphorder=14 if cancersite=="Bladder (C67)"
	*replace graphorder=16 if cancersite=="CNS (C71-72)" 
	replace graphorder=15 if cancersite=="Thyroid (C73)"
	replace graphorder=16 if cancersite=="NHL (C82-85)" 
	*replace graphorder=19 if cancersite=="Multiple myeloma (C90)" 
	*replace graphorder=20 if cancersite=="Leukaemia (C91-95)"


	gsort graphorder stage stage_n

	gen n = _n
	gen graphorder2=101-n
	drop graphorder
	rename graphorder2 graphorder

	gen labelxpos = 0.15
	gen labelnpos=7
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
	
	foreach var in hr uci lci {
		replace `var'=. if displayhrci=="(not calculated)"
	}
	replace displayhrci="Adj HR (95% CI)" if n==1
	replace nevents="N cancers" if n==1
	 
	scatter graphorder labelxpos if stage==0, m(i) mlab(cancersite) mlabcol(black) mlabsize(vsmall) ///
	|| scatter graphorder labelnpos if stage==0, m(i) mlab(nevents) mlabcol(black) mlabsize(vsmall) ///
	|| scatter graphorder hrxpos if stage==0, m(i) mlab(displayhrci) mlabcol(black) mlabsize(vsmall) ///
	|| scatter graphorder labelxpos if stage==1, m(i) mlab(stage2) mlabcol(black) mlabsize(vsmall) ///
	|| scatter graphorder labelnpos if stage==1, m(i) mlab(nevents) mlabcol(black) mlabsize(vsmall) ///
	|| scatter graphorder hr if stage==1, mcol(black) msize(vsmall) msymbol(D) ///
	|| rcap lci uci graphorder if stage==1, hor mcol(black) lcol(black) ///
	|| scatter graphorder hrxpos if stage==1, m(i) mlab(displayhrci) mlabcol(black) mlabsize(vsmall) ///
	///		
	|| scatter graphorder labelxpos if stage==2, m(i)  ///
	|| scatter graphorder labelxpos if stage==2, m(i) mlab(stage2) mlabcol(black) mlabsize(vsmall) ///
	|| scatter graphorder labelnpos if stage==2, m(i) mlab(nevents) mlabcol(black) mlabsize(vsmall) ///
	|| scatter graphorder hr if stage==2, mcol(black) msize(vsmall) msymbol(D) ///
	|| rcap lci uci graphorder if stage==2, hor mcol(black) lcol(black) ///	
	|| scatter graphorder hrxpos if stage==2, m(i) mlab(displayhrci) mlabcol(black) mlabsize(vsmall) ///
	///
	|| scatter graphorder labelxpos if stage==9, m(i)  mlabcol(gs8)  ///
	|| scatter graphorder labelxpos if stage==9, m(i) mlab(stage2) mlabcol(gs8) mlabsize(vsmall) ///
	|| scatter graphorder labelnpos if stage==9, m(i) mlab(nevents) mlabcol(gs8) mlabsize(vsmall) ///
	|| scatter graphorder hr if stage==9, mcol(gs8) msize(vsmall) msymbol(D) ///
	|| rcap lci uci graphorder if stage==9, hor mcol(gs8) lcol(gs8) ///	
	|| scatter graphorder hrxpos if stage==9, m(i) mlab(displayhrci) mlabcol(gs8) mlabsize(vsmall) ///
	///
	ylabels(none) ytitle("") xscale(log range(50)) xlab(0.5 1 2 4 6) ///
	xtitle("Hazard ratio & 95% CI") xline(1,lp(dash)) legend(off) ///
	ysize(13) graphregion(color(white))
		
		

graph play "J:\EHR-Working\Helena\bonefractures_cs\dofiles\Data_analysis\dofiles\edit_axis.grec"
graph save "$results_an_dem/forest_dementia_stage", replace
graph export "$results_an_dem\forest_dementia_stage.emf", as(emf) name("Graph") replace


/*
