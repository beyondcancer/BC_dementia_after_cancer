
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
	
	/* Dementia gold */
	merge m:1 medcode using "$codelists//cr_codelist_dementiaBASSILpaper_gold.dta", keep(match) nogen
	
	gen dementia_BASSIL_gold=1
	save "${datafiles}\\cr_all_events_dementiaBASSIL_GOLD.dta", replace			

	
	
********************************************************************************	
* 2. Identify PATIENTS who had history of smi before the index date
********************************************************************************	
	use "$cohort_patids_gold", clear
	keep if cancer=="lun"
	tab exposed
	sort e_patid
	joinby e_patid using "$datafiles//cr_all_events_dementiaBASSIL_GOLD.dta"

	bysort e_patid setid (eventdate): keep if _n==1
	
	save "${datafiles}\\listpatid_dementiaBASSIL_GOLD.dta", replace		
	
	*HARRIET events GOLD
	 use "$datafiles\cr_all_mh_dx_outcomeevents_gold.dta", clear
keep if binaryvar=="dementia"
	bysort e_patid (eventdate): keep if _n==1
	save "${datafiles}\\listpatid_dementiaHARRIET_GOLD.dta", replace	
	
	*HARRIET events GOLD+HES
		 use "$datafiles\cr_all_mh_dx_outcomeevents_gold.dta", clear
append using "$datafiles\cr_all_mh_outcomeevents_HES_gold.dta"
keep if binaryvar=="dementia"
	bysort e_patid (eventdate): keep if _n==1
	save "${datafiles}\\listpatid_dementiaHARRIET_GOLD_HES.dta", replace	
	
	use "Z:\GPRD_GOLD\Krishnan\20_000268\20_000268_2nd_Delivery (full data)\datafiles\cr_coredataset/cr_coredataset_gold", clear
	keep if cancer=="col"
	tab exposed
	
	*BASSIL codes GOLD ONLY
	merge 1:1 setid e_patid using  "${datafiles}\\listpatid_dementiaBASSIL_GOLD.dta", keep (match master) nogen
	
	*HArriet codes - primary care, secondary care, deaths
	merge 1:1 setid e_patid using "$datafiles_raw/cr_listpatid_dementia_outcome_categories_gold", keep(match master) nogen
	
		*HArriet codes - GOLD and HES
	merge m:1 e_patid using "$datafiles_raw/listpatid_dementiaHARRIET_GOLD_HES", keep(match master) nogen
	
	*Harriet codes GOLD only
	merge m:1 e_patid using "${datafiles}\\listpatid_dementiaHARRIET_GOLD.dta", keep(match master) nogen
	tab exposed
	
	

	
	drop if eventdate<indexdate
	tab exposed

	tab h_odementia
	drop if h_odementia==1
	
	sum main0_datedementia
	keep if cancer=="lun"

*restrict to lun cancers diagnosed in cprd gold
*drop if exposed==1 & lun_cancer_gold==.
tab exposed

rename indexdate doentry
gen doexit = min(doendcprdfup, eventdate, d(29mar2021))



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
*drop anyunexposed
bysort setid: egen anyunexposed=min(exposed)
drop if anyunexposed==1

*Drop controls without a case
gsort setid -exposed
*drop anyexposed
bysort setid: egen anyexposed=max(exposed)
drop if anyexposed==0


gen dementia= 1 if eventdate<= doexit
tab dementia exposed, col

//*stset underlying timescale follow-up*/
sort e_patid exposed
gen id = _n
stset doexit, id(id) failure(dementia = 1) enter(doentry) origin(doentry) exit(doexit) scale(365.25)
sts graph, by(exposed) cumhaz riskt
stcox exposed if age>60, strata(setid) iterate(1000)
stcox exposed, strata(setid) iterate(1000)




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

