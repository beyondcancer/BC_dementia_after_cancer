capture log close

log using "$logfiles_an_dem\an_Primary_A2_cox-model-figures-interactions_dementia.txt", replace

***********************************************************************************************
*set trace on 
*set tracedepth 1
*5 9-panel figures for the appendix (9 top cancers, 5 outcomes with enough events)
***********************************************************************************************
foreach db of  global databases {
foreach outcome in dementia {
foreach cancer of global cancersites {

		if "`cancer'"=="bla" local cancerlong "Bladder (C67)"
		if "`cancer'"=="cns" local cancerlong "Brain/CNS (C71-72)"
		if "`cancer'"=="col" local cancerlong "Colorectal (C18-C20)"
		if "`cancer'"=="gas" local cancerlong "Stomach (C16)"
		if "`cancer'"=="kid" local cancerlong "Kidney (C64)"
		if "`cancer'"=="leu" local cancerlong "Leukemia (C91-95)"
		if "`cancer'"=="liv" local cancerlong "Liver (C22)"
		if "`cancer'"=="lun" local cancerlong "Lung (C34)"
		if "`cancer'"=="mel" local cancerlong "Malignant melanoma (C43)"
		if "`cancer'"=="mye" local cancerlong "Multiple myeloma (C90)"
		if "`cancer'"=="nhl" local cancerlong "Non-Hodgkin lymphoma (C82-85)"
		if "`cancer'"=="oes" local cancerlong "Oesophageal (C15)"
		if "`cancer'"=="ora" local cancerlong "Oral Cavity (C00-06)"
		if "`cancer'"=="pan" local cancerlong "Pancreas (C25)"
		if "`cancer'"=="pro" local cancerlong "Prostate (C61)"
		if "`cancer'"=="thy" local cancerlong "Thyroid (C73)"
		if "`cancer'"=="bre" local cancerlong "Breast (C50)"
		if "`cancer'"=="cer" local cancerlong "Cervix (C53)"
		if "`cancer'"=="ova" local cancerlong "Ovaries (C56)"
		if "`cancer'"=="ute" local cancerlong "Uterus (C54-55)"
		

use "$results_an_dem/an_Primary_A2_cox-model-estimates_int_processout_aandg_dementia.dta", clear
rename cancer cancersite
merge 1:1 cancersite intvar level using "$results_an_dem/an_7Primary_A2_rawnumbers_int_dementia.dta"
rename cancersite cancer
drop if _m==2

gen nevents=nfailunexp+nfailexp

keep if outcome=="`outcome'" & cancer=="`cancer'"
gen stratum = "Male" if intvar=="gender" & level == 1
replace stratum = "Female" if intvar=="gender" & level == 2

replace stratum = "Age 18-49y" if intvar=="age_cat_dementia" & level == 1
replace stratum = "Age 50-59y" if intvar=="age_cat_dementia" & level == 2 
replace stratum = "Age 60-69y" if intvar=="age_cat_dementia" & level == 3
replace stratum = "Age 70-79y" if intvar=="age_cat_dementia" & level == 4
replace stratum = "Age 80+y" if intvar=="age_cat_dementia" & level == 5


replace stratum = "White" if intvar=="eth5_comb" & level == 0
replace stratum = "South Asian" if intvar=="eth5_comb" & level == 1
replace stratum = "Black" if intvar=="eth5_comb" & level == 2
replace stratum = "Other or Mixed" if intvar=="eth5_comb" & level == 3

replace stratum = "Years 1998-2002" if intvar=="calendaryearcat3" & level == 1 
replace stratum = "Years 2003-2008" if intvar=="calendaryearcat3" & level == 2
replace stratum = "Years 2009-2015" if intvar=="calendaryearcat3" & level == 3
replace stratum = "Years 2016-2018" if intvar=="calendaryearcat3" & level == 4

replace stratum = "Lower deprivation" if intvar=="mostdeprived" & level == 0 
replace stratum = "Higher deprivation" if intvar=="mostdeprived" & level == 1 

replace stratum = "North" if intvar=="region_cat" & level == 1
replace stratum = "East" if intvar=="region_cat" & level == 2
replace stratum = "West" if intvar=="region_cat" & level == 3
replace stratum = "South" if intvar=="region_cat" & level == 4
replace stratum = "London" if intvar=="region_cat" & level == 5

replace stratum = "No CVD at baseline" if intvar=="b_cvd" & level == 0 
replace stratum = "CVD at baseline" if intvar=="b_cvd" & level == 1 

list 
gen esthr = string(hr, "%4.2f") + " (" + string(lci, "%4.2f") + ", " + string(uci, "%4.2f") + ")"
gen pintstr = "p="+ string(pint, "%5.3f") if pint>=0.001 & pint<0.01
replace pintstr = "p="+ string(pint, "%4.2f") if pint>=0.01
replace pintstr = "p<0.001" if pint<0.001

*Reorder to bring prior cvd and hypertension before the 2 time interactions
gen interacno = 1 if intvar!=intvar[_n-1]
replace interacno=sum(interacno)
qui summ interacno if intvar=="timesincediag3"
replace interacno = r(mean)-0.5 if intvar=="allcvd_diag" 
replace interacno = r(mean)-0.2 if intvar=="hypertension"

sort interacno level

gen increment = 1

by interacno: replace increment = 2 if _n==1

gen nrev=sum(increment)
qui summ nrev
local nmax = r(max)
*local nmax = 27

gen n=`nmax' + 1 - nrev



	/* gen new variable for offscale lcis and ucis*/ 
	gen nogen=1 if hr <0.5 | hr>15
	replace hr=.  if nogen==1
	replace lci=. if nogen==1 
	replace uci=. if nogen==1
	gen lcimin = 0.5 if lci <0.5 & hr !=.
	replace lci = 0.5 if lcimin == 0.5
	gen ucimax = 15 if uci > 15 & hr !=.
	replace uci = 15 if ucimax == 15

	replace uci=0.5 if uci<0.5
	gen overlab = ">"
	gen underlab = "<"
	
	replace esthr="[could not calculate]" if lci==. 
bysort intvar (level): replace pintstr="" if _n!=1 
 
*CReate headers for graphs
insobs 1, before(1) 
replace n=31 if n==.
 tostring nevents, gen(nevents_str)
 replace nevents_str="N outcomes" if n==31
 replace stratum="Variable" if n==31 
 replace esthr="HR (95% CI)" if n==31 
 replace pintstr="P-int" if n==31 

cap drop estx px interacx
gen interacx = 0.01
gen lab_events=0.1
gen estx = 18
gen px = 70
 
 scatter n hr , mcol(black) mlabsize(vsmall) ///
	|| scatter n interacx, m(i) mlab(stratum) mlabcol(black) ///
	|| rcap uci lci n, hor lc(black) ///
	|| scatter n lab_events, m(i) mlab(nevents_str) mlabcol(black) ///
	|| scatter n estx, m(i) mlab(esthr) mlabcol(black) mlabsize(vsmall) ///
	|| scatter n px, m(i) mlab(pintstr) mlabcol(black)  mlabsize(vsmall) ///
	|| scatter n lcimin, mlab(underlab) mlabpos(0) mlabsize(small) mlabcolor(black) m(i) ///
	|| scatter n ucimax, mlab(overlab) mlabpos(0) mlabsize(small) mlabcolor(black) m(i) ///
	|| , xscale(range (0.1 90) log) xlab(0.5 1 2 4 6) yscale(range(20)) ysize(4) ylab(none) xtitle("HR and 95% CI") ytitle("") legend(off) title("`cancerlong'") name(`cancer', replace) xline(1, lp(dash)) graphregion(color(white))
 
} /*cancer*/
*graph export "$results\an_Primary_A2_cox-model-figures-interactions_Appendixfig_`outcome'_`db'_dementia.emf", replace

 
graph combine $cancersites, altshrink rows(4)  graphregion(color(white))
graph export "$results_an_dem\an_Primary_A2_cox-model-figures-interactions_Appendixfig_`outcome'_`db'_dementia.emf", replace
graph export "$results_an_dem\an_Primary_A2_cox-model-figures-interactions_Appendixfig_`outcome'_`db'_dementia.jpg", replace
graph export "$results_an_dem/forest_interaction_`outcome'.tif", name("Graph") replace width(10000) 
*graph drop _all
} /*outcome*/
} /*db*/



/*
graph combine "$results/nhl_hfcardiomyopathy" "$results/bre_vte" "$results/col_vte" , altshrink cols(1) ysize(10)
graph export "$results/an_Primary_A2_cox-model-figures-interactions_figure2.emf", replace
graph export "$results/an_Primary_A2_cox-model-figures-interactions_figure2.pdf", replace

erase "$results/nhl_hfcardiomyopathy.gph"
erase "$results/bre_vte.gph"
erase "$results/col_vte.gph"


capture log close
