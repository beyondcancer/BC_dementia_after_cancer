*create alternative dementia definitions for sensitivity analyses

********************************************************************
*2. SENSE: removing less specific dementia codes
*(excluding other G31 codes)

*diagnosis for main anlaysis ([mh]_main)
use "$cohort_patids_gold", clear

keep e_patid setid indexdate exposed
count
joinby e_patid using "$datafiles\cr_all_events_dementia_gold"

drop if nonspecific==1
drop if icd=="G31" | icd=="G31.0" | icd=="G31.1" | icd=="G31.2" | icd=="G31.8" | icd=="G31.9"  
tab icd
drop if eventdate==.

gen main0=1 if eventdate>=indexdate & h_o_code!=1  
gen main0_date=eventdate if main0==1

*First dementia type recorded
bysort e_patid setid (eventdate): gen dem_type=type if _n==1 	
	
*Exclusion flags: 

	*diagnosis ever before cancer
	gen h_o=1 if eventdate<indexdate 
	replace h_o=1 if h_o_code==1 /*history of dementia code ever*/ 
	
	*select first dx each mh group after index date
	collapse (max) h_o main0 (min) main0_date dem_type, by(e_patid setid  indexdate exposed)			

	*Reshape dataset wide
	gen j="dementia"
	reshape wide h_o main0 main0_date dem_type, i(e_patid setid) j(j, string)
	
save "$datafiles_an_dem/cr_listpatid_dementia_specific_outcome_categories_gold", replace



********************************************************************
*3. SENSE: defining dementia using primary care data only

*diagnosis for main anlaysis ([mh]_main)
use "$cohort_patids_gold", clear

keep e_patid setid indexdate exposed
count
joinby e_patid using "$datafiles\cr_all_events_dementia_gold"

drop if source==3 | source==4 /*drop records from hes and ons*/

drop if eventdate==.

gen main0=1 if eventdate>=indexdate & h_o_code!=1  
gen main0_date=eventdate if main0==1

*First dementia type recorded
bysort e_patid setid  (eventdate): gen dem_type=type if _n==1 	
	
*Exclusion flags: 

	*diagnosis ever before cancer
	gen h_o=1 if eventdate<indexdate 
	replace h_o=1 if h_o_code==1 /*history of dementia code ever*/ 
	
	*select first dx each mh group after index date
	collapse (max) h_o main0 (min) main0_date dem_type, by(e_patid setid indexdate exposed)			

	*Reshape dataset wide
	gen j="dementia"
	reshape wide h_o main0 main0_date dem_type, i(e_patid setid) j(j, string)
	
save "$datafiles_an_dem/cr_listpatid_dementia_pricare_outcome_categories_gold", replace


