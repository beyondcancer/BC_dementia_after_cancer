
cap log close
log using "$logfiles_create_dataset//cr_all_dementia_gold_events_gold.txt", replace
********************************************************************************


********************************************************************************
* 1.	SEARCH FOR EVENTS OF dementia_gold *
********************************************************************************
	
	use "${rawdata_gold}\\Clinical_extract_combined_gold.dta", clear
	append using "${rawdata_gold}\\Referral_Extract_combined_gold.dta"
		
	keep e_patid eventdate medcode
	sort e_patid medcode eventdate
	drop if eventdate==.	
	
	/* dementia_gold */
	merge m:1 medcode using "$codelists//cr_codelist_dementiafinal_gold.dta", keep(match) nogen
	
	gen dementia_gold=1

	save "${datafiles}\\cr_all_events_dementia_gold_GOLD.dta", replace			

	
	
********************************************************************************	
* 2. Identify PATIENTS who had history of smi before the index date
********************************************************************************	
	use "$cohort_patids_gold", clear
	
	sort e_patid
	joinby e_patid using "$datafiles//cr_all_events_dementia_gold_GOLD.dta"

	bysort e_patid setid (eventdate): keep if _n==1
	
	save "${datafiles}\\cr_listpat_dementia_gold_outcomes_gold.dta", replace
	
cap log close	
use "$datafiles_an_dem/cr_dataforDEManalysis_gold.dta", clear
merge 1:1 setid e_patid using  "${datafiles}\\cr_listpat_dementia_gold_outcomes_gold.dta", keep (match master)
keep if cancer=="bre"
drop if eventdate <= indexdate /*drops history dementia*/
rename indexdate doentry
gen doexit = min(doendcprdfup, eventdate, d(29mar2021))
gen dem_new= 1 if eventdate<= doexit
tab dem_new exposed, col

sort e_patid exposed
gen id = _n
stset doexit, id(id) failure(dementia = 1) enter(doentry) origin(doentry) exit(doexit) scale(365.25)
stcox exposed, strata(set) iterate(1000)


