
cap log close
log using "$logfiles_an_dem/cr_dataforanalysis_aurum.txt", replace t
********************************************************************************


use  "$datafiles_core/cr_coredataset_aurum.dta", clear


	/* mh outcomes */
	desc using "$datafiles_raw/cr_listpatid_outcome_categories_aurum.dta"
	merge 1:1 setid e_patid using "${datafiles_raw}/cr_listpatid_outcome_categories_aurum.dta"
	foreach outcome in anxiety  depression fatigue cognitivedysfunction  selfharm ///
	sexualdysfunction sleepdisorder eating_disorder heavy_alc_cons suicide { 
	}
	drop _m
	merge 1:1 setid e_patid using "${datafiles_raw}/cr_listpatid_outcome_categories_HES_only_aurum.dta"
drop _m
	
********************************************************************************
*APPLY EXCLUSIONS
********************************************************************************



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


*Drop individuals with b_smi prior to index date
tab exposed
count if b_smi==1 & exposed==1
drop if b_smi==1 & exposed==1
count if b_smi==1 & exposed==1
drop if b_smi==1 & exposed==0
********************************************************************************


*Check follow-up is correct
count if doendcprdfup<indexdate & exposed==1
count if doendcprdfup<indexdate & exposed==0

drop if doendcprdfup<indexdate
assert	doendcprdfup>=indexdate
	
*Check all cases have at least one control
gsort setid exposed
bysort setid: egen anyunexposed=min(exposed)
drop if anyunexposed==1

*Drop controls without a case
gsort setid -exposed
bysort setid: egen anyexposed=max(exposed)
drop if anyexposed==0

/******************************************************************************/
recode h_odementia .=0
tab h_odementia age_cat if exposed==1, col
tab h_odementia age_cat if exposed==0, col

drop if h_odementia==1 & exposed==1
drop if h_odementia==1 & exposed==0

*Check all cases have at least one control
gsort setid exposed
drop anyunexposed
bysort setid: egen anyunexposed=min(exposed)
drop if anyunexposed==1

*Drop controls without a case
gsort setid -exposed
drop anyexposed
bysort setid: egen anyexposed=max(exposed)
drop if anyexposed==0



tab exposed
* SAVA DATASET
save "$datafiles/cr_dataforDEManalysis_aurum.dta", replace

log close


