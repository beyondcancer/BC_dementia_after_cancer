*Investigate dementia codes

clear
capture log close
*log using "$logfiles\cr_list_patid_outcome_categories_aurum.txt", replace text

/*
********************************************************************
Identify:
*1. Outcome: diagnosis after cancer: certainty level (choose most certain) + date
	-diagnosis for main anlaysis ([mh]_main)
	-diagnosis for sensitivity anlaysis restricting to definite codes ([mh]_definite)
*2. Exclusion flags: 
	-diagnosis 365 days before cancer: binary flag (dx_365d_pre_cancer)
	-diagnosis ever before cancer: binary flag for exclusion in sense analysis (dx_pre_cancer)
********************************************************************
*/

********************************************************************
*1. Outcome: diagnosis after cancer: choose earliest

*diagnosis for main anlaysis ([mh]_main)
use $cohort_patids_aurum, clear
keep e_patid setid indexdate exposed cancer
count
joinby e_patid using "$datafiles\cr_listpat_mh_outcomeevents_aurum"

keep if binaryvar=="dementia"
*diagnosis ever before cancer: binary flag for exclusion in sense analysis ([mh]_pre_cancer)
drop if obsdate<indexdate 
	
	
gen main0=1 if obsdate>indexdate & certlevel!=4 /* MH dx after cancer date and not a h/o code*/
gen main0_date=obsdate if main0==1
tab main0 binaryvar

*First dementia type recorded
bysort e_patid setid binaryvar (obsdate): gen dem_type=type if _n==1 	
*First dementia source recorded
bysort e_patid setid binaryvar (obsdate): gen dem_source=source if _n==1 		



	
*select first dx each mh group after index date
bysort e_patid setid (obsdate): keep if _n==1		
tab dem_source, miss
tab binary
tab type
tab exposed if cancer=="ora" /*expect ~7911 dementia cases*/


*merge on aurum dictionary 
merge m:1 lshtmcode using "$datafiles//aurummedicaldict_lookup.dta"
drop if _m==2
drop _m
keep e_patid setid cancer exposed lshtmcode term lshtpcode icd main0_date
rename main0_date main0_datedementia
save "$datafiles\all_dementia_codes", replace

qui {
	foreach cancer in liv lun mel cns {
	noi di "`cancer'"
use "$datafiles/cr_dataforanalysis_aandg_`cancer'.dta", clear
keep if cprd_db==1
keep e_patid setid cancer exposed main0_datedementia do* index
tab exposed
tab exposed if main0_datedementia!=.
rename main0_datedementia dementia_date
merge 1:1 e_patid setid cancer  using "$datafiles\all_dementia_codes"
keep if cancer=="`cancer'" 
drop if _m==2

count if main0_datedementia!=dementia_dat
br if main0_datedementia!=dementia_date
format dementia_date %td

noi tab icd if exposed==0, sort freq
noi tab icd if exposed==1, sort freq

noi tab term if exposed==0, sort freq
noi tab term if exposed==1, sort freq
}
}


use $cohort_patids_aurum, clear
keep e_patid setid indexdate exposed cancer
keep if cancer=="liv"
count
joinby e_patid using "$datafiles\cr_listpat_mh_outcomeevents_aurum"
keep if cancer=="liv"
tab binaryvar
keep if binaryvar=="dementia"
tab source
bysort e_patid setid (obsdate): keep if _n==1
tab source

tab source if obsdate>=indexdate
sum source obsdate index exposed



