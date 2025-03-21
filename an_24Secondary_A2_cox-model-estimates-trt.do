cap log close
args  db site
log using "$logfiles_an_dem/an_Primary_A2_cox-model-estimates_treatment_dementia.txt", replace t
 tempname myhandle
   file open `myhandle' using "$results_an_dem/an_24_SENSE_chemo_use.txt", write  replace 

/***** COX MODEL ESTIMATES FOR CRUDE, ADJUSTED AND SENSITIVITY ANALYSES ****/
foreach db of  global databases {
	foreach site of global cancersites {
	foreach trt in chemo  {
	foreach outcome in dementia {
	    
	foreach year in 1 {		
	use "$datafiles_an_dem/cr_dataforDEManalysis_`db'_`site'.dta", clear 

	drop if indexdate<=d(01apr2014)
	


	include "$dofiles_an_dem/inc_excludepriorandset_dementia.do" /*excludes prior specific outcomes and st sets data*/
 	
	tab exposed
	gen indexdate=doentry-365.25
	gen exposed_trt=exposed
	replace exposed_trt=2 if dof_chemo!=.
	tab exposed_trt
	replace exposed_trt=1 if (dof_chemo<indexdate-31 | dof_chemo>indexdate+365.25) & exposed==1
	replace exposed_trt=1 if dof_chemo>doexit & exposed==1
	tab exposed_trt
	stop 
	tab `outcome' exposed_trt , col chi miss
 
	file write `myhandle' _n "`site'" _tab 
	count if exposed==1
	local total=`r(N)'	
	foreach x in 1 2 {
	count if exposed_trt==`x'
	local n=`r(N)'
	local percent=(`n'/`total')*100
	file write `myhandle' (`total') _tab %4.1f (`n') " (" %4.1f (`percent') ")" _tab
	}
	 
	*** CRUDE AND ADJUSTED MODELS
	*Only run models if there are >=1 failures in both groups
	count if exposed_trt == 2 & _d==1
	local exposed_trtfailures2 = `r(N)'
	count if exposed_trt == 1 & _d==1
	local exposed_trtfailures = `r(N)'
	count if exposed_trt == 0 & _d==1
	local controlfailures = `r(N)'
	if `exposed_trtfailures' >=1 & `controlfailures' >=1 & `exposed_trtfailures2' >=1 {
	
	cap noi stcox i.exposed_trt $covariates_common, strata(set) iterate(1000)
	if _rc==0 estimates save "$results_an_dem/an_Primary_A2_cox-model-estimates_adj_chemo_`site'_`outcome'_`db'_`year'", replace
	
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
	else {
		local stage stage_tnm
	}
	drop if `stage'==4
	drop if `stage'==0 | `stage'==99 
	cap noi stcox i.exposed_trt $covariates_mh_an, strata(set) iterate(1000)
	if _rc==0 estimates save "$results_an_dem/an_Primary_A2_cox-model-estimates_adjstage_chemo_`site'_`outcome'_`db'_`year'", replace	
} /*if at least 1 ev per group for crude and adjusted models*/
} /*year from dx*/

} /* outcomes */
} /*trt type*/
}
}

log close
