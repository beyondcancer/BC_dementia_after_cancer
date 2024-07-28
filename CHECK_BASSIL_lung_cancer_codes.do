
cap log close
********************************************************************************


********************************************************************************
* 1.	SEARCH FOR EVENTS OF dementia_gold *
********************************************************************************
	
	use "${rawdata_gold}\\Clinical_extract_combined_gold.dta", clear
	append using "${rawdata_gold}\\Referral_Extract_combined_gold.dta"
		
	keep e_patid eventdate medcode
	sort e_patid medcode eventdate
	drop if eventdate==.	
	
	/* Lung cancer gold */
	merge m:1 medcode using "$codelists//cr_codelist_lungcancerBASSILpaper_gold.dta", keep(match) nogen
	
	gen lun_cancer_gold=1
	save "${datafiles}\\cr_all_events_lungcancer_gold_GOLD.dta", replace			

	
	
********************************************************************************	
* 2. Identify PATIENTS who had history of smi before the index date
********************************************************************************	
	use "$cohort_patids_gold", clear
	keep if exposed==1 
	keep if cancer=="lun"
	sort e_patid
	joinby e_patid using "$datafiles//cr_all_events_lungcancer_gold_GOLD.dta"

	bysort e_patid setid (eventdate): keep if _n==1
	keep e_patid  setid exposed lun_cancer_gold eventdate

	save "${datafiles}\\cr_listpat_luncancer_outcomes_gold.dta", replace

	
	
use "$datafiles_an_dem/cr_dataforDEManalysis_gold.dta", clear
keep if cancer=="lun"
*merge 1:1 setid e_patid using  "${datafiles}\\cr_listpat_luncancer_outcomes_gold.dta", keep (match master)

*restrict to lun cancers diagnosed in cprd gold
*drop if exposed==1 & lun_cancer_gold==.
tab exposed

rename indexdate doentry
gen doexit = min(doendcprdfup, main0_datedementia, d(29mar2021))



*Censor controls at date of censor in cases
gen censordatecancer_temp=doexit if exposed==1
bysort setid: egen censordatecancer=max(censordatecancer_temp)
replace doexit = censordatecancer if doexit>censordatecancer

*Censor cases at date of all cases censored
gsort setid -exposed -doexit
gen censordatecontrol_temp=doexit if exposed==0
bysort setid: egen censordatecontrol=max(censordatecontrol_temp)
gen flag=1 if doexit>censordatecontrol

*list setid exposed doexit censordatecontrol  if flag==1 
replace doexit = censordatecontrol if doexit>censordatecontrol
format censordatecontrol %td

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

gen dementia= 1 if main0_datedementia<= doexit
tab dementia exposed, col

//*stset underlying timescale follow-up*/
/*sort e_patid exposed
gen id = _n
stset doexit, id(id) failure(dementia = 1) enter(doentry) origin(doentry) exit(doexit) scale(365.25)
sts graph, by(exposed) cumhaz riskt
stcox exposed if age>60
stcox exposed, strata(setid) iterate(1000)
stcox exposed i.age_cat
stop */


/*Restricting to cancers diagnosed in primary care only (~73% ) of all lung cancers - makes increased risk greater*/


gen d=1
gen m=7
gen dob=mdy(m,1,yob)
format dob %td
br dob yob

sort e_patid exposed
gen id = _n
*steset with age as underlying timescale to check incidence by age
stset doexit, id(id) failure(dementia = 1) enter(doentry) origin(dob) exit(doexit) scale(365.25)
sts graph, by(exposed) cumhaz riskt
stcox exposed if age>60
stcox exposed, strata(setid) iterate(1000)

