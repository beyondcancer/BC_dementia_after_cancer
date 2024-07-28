
cap log close
log using "$logfiles_an_dem/cr_dataforDEManalysis_Gold.txt", replace t
********************************************************************************

	*HARRIET events GOLD
	 use "$datafiles\cr_all_mh_dx_outcomeevents_gold.dta", clear
	keep if binaryvar=="dementia"
	bysort e_patid (eventdate): keep if _n==1
	save "${datafiles}\\listpatid_dementiaHARRIET_GOLD.dta", replace	
	
	
merge 1:m using  "$datafiles_core/cr_coredataset_gold.dta", keep(match using)

	

********************************************************************************
*APPLY EXCLUSIONS
********************************************************************************

tab age_cat exposed, col

*Drop those with missing BMI, smoking status and IMD
tab exposed
misstable summarize bmi smokstatus imd5 if exposed==0
misstable summarize bmi smokstatus imd5 if exposed==1

foreach var in smokstatus imd5 {
count if `var'==. & exposed==1
drop if `var'==. & exposed==1
count if `var'==. & exposed==0
drop if `var'==. & exposed==0
}
tab age_cat exposed, col

*Drop individuals with b_smi prior to index date
tab exposed
count if b_smi==1 & exposed==1
drop if b_smi==1 & exposed==1
count if b_smi==1 & exposed==1
drop if b_smi==1 & exposed==0
********************************************************************************

tab age_cat exposed, col

*Check follow-up is correct
count if doendcprdfup<=indexdate & exposed==1
count if doendcprdfup<=indexdate & exposed==0

drop if doendcprdfup<=indexdate

gen h_odementia=1 if eventdate<indexdate
drop if h_odementia==1 & exposed==1
drop if h_odementia==1 & exposed==0
	
*Check all cases have at least one control
gsort setid exposed
bysort setid: egen anyunexposed=min(exposed)
drop if anyunexposed==1

tab age_cat exposed, col

*Drop controls without a case
gsort setid -exposed
bysort setid: egen anyexposed=max(exposed)
drop if anyexposed==0

tab age_cat exposed, col


/******************************************************************************/








tab exposed
* SAVA DATASET
save "$datafiles_an_dem/cr_dataforDEManalysis_gold.dta", replace

log close


