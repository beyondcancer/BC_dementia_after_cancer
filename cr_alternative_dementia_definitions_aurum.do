
********************************************************************
*2. SENSE: removing less specific dementia codes

*diagnosis for main anlaysis ([mh]_main)
use "$cohort_patids_aurum", clear
keep e_patid setid indexdate exposed
count
joinby e_patid using "$datafiles\cr_all_events_dementia_aurum"

drop if obsdate==.
drop if icd=="G31" | icd=="G31.0" | icd=="G31.1" | icd=="G31.2" | icd=="G31.8" | icd=="G31.9"  

gen main0=1 if obsdate>=indexdate & h_o_code!=1  
gen main0_date=obsdate if main0==1

*First dementia type recorded
bysort e_patid setid  (obsdate): gen dem_type=type if _n==1 	
	
*Exclusion flags: 

	*diagnosis ever before cancer
	gen h_o=1 if obsdate<indexdate 
	replace h_o=1 if h_o_code==1 /*history of dementia code ever*/ 

	
	*select first dx each mh group after index date
	collapse (max) h_o main0 (min) main0_date dem_type, by(e_patid setid indexdate exposed)			

	*Reshape dataset wide 
	gen j="dementia"
	reshape wide h_o main0 main0_date dem_type, i(e_patid setid) j(j, string)
save "$datafiles_an_dem/cr_listpatid_dementia_specific_outcome_categories_aurum", replace

*Derives alternative definitions for dementia 

*3. SENSE: defining dementia using primary care data only
*diagnosis for main anlaysis ([mh]_main)
use "$cohort_patids_aurum", clear
keep e_patid setid indexdate exposed
count
joinby e_patid using "$datafiles\cr_all_events_dementia_aurum"

drop if obsdate==.
drop if source==3 | source==4 /*drop records from hes and ons*/

gen main0=1 if obsdate>=indexdate & h_o_code!=1
gen main0_date=obsdate if main0==1

*First dementia type recorded
bysort e_patid setid (obsdate): gen dem_type=type if _n==1 	
	
*Exclusion flags: 

	*diagnosis ever before cancer
	gen h_o=1 if obsdate<indexdate 
	replace h_o=1 if h_o_code==1 /*history of dementia code ever*/ 

	
	*select first dx each mh group after index date
	collapse (max) h_o main0 (min) main0_date dem_type, by(e_patid setid indexdate exposed)			

	*Reshape dataset wide 
	gen j="dementia"
	reshape wide h_o main0 main0_date dem_type, i(e_patid setid) j(j, string)
	
save "$datafiles_an_dem/cr_listpatid_dementia_pricare_outcome_categories_aurum", replace

capture log close