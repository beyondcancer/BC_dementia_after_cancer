cap log close
args  db site
log using "$logfiles_an_mh/an_Primary_A2_cox-model-estimates_treatment_dementia.txt", replace t

/***** COX MODEL ESTIMATES FOR CRUDE, ADJUSTED AND SENSITIVITY ANALYSES ****/
foreach db of  global databases {
	foreach site of global cancersites {
	foreach trt in chemo surg {
	foreach outcome in dementia {
	    
	foreach year in 1 {		
	use "$datafiles/cr_dataforDEManalysis_`db'_`site'.dta", clear 
	
	drop if cal_year<2012
	
	tab exposed
	gen exposed_trt=exposed
	replace exposed_trt=2 if exposed==1 & `trt'==1
	tab exposed_trt
	replace exposed_trt=1 if (do`trt'<indexdate-31 | do`trt'>indexdate+365.25) & exposed==1
	replace exposed_trt=1 if do`trt'>doendcprdfup & exposed==1
	tab exposed_trt
	 
	*Exclude those with h/o dementia
	drop if h_o`outcome'==1 /*h/o prior to indexdate*/
	drop if h_o365_1`outcome'==1 /*h/o prior to 1 year from index*/
	dib "`site' `outcome' `db'", stars

	*include "$Dodir\analyse\inc_setupadditionalcovariates.do" /*defines female and site specific covariates*/
	include "$dofiles\analyse_mental_health\dementia/inc_excludepriorandset_dementia.do" /*excludes prior specific outcomes and st sets data*/
	tab `outcome' exposed_trt , col chi miss
 
	*** CRUDE AND ADJUSTED MODELS
	*Only run models if there are >=1 failures in both groups
	count if exposed_trt == 2 & _d==1
	local exposed_trtfailures2 = `r(N)'
	count if exposed_trt == 1 & _d==1
	local exposed_trtfailures = `r(N)'
	count if exposed_trt == 0 & _d==1
	local controlfailures = `r(N)'
	if `exposed_trtfailures' >=1 & `controlfailures' >=1 & `exposed_trtfailures2' >=1 {
	
	cap noi stcox i.exposed_trt $covariates_mh_an, strata(set) iterate(1000)
	if _rc==0 estimates save "$results_dem/an_Primary_A2_cox-model-estimates_adj_`trt'_`site'_`outcome'_`db'_`year'", replace
	
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
	drop if `stage'==3 | `stage'stage==4
	replace `stage'=0 if `stage'==99 | `stage'==.
	cap noi stcox i.exposed_trt $covariates_mh_an i.`stage', strata(set) iterate(1000)
	if _rc==0 estimates save "$results_dem/an_Primary_A2_cox-model-estimates_adjstage_`trt'_`site'_`outcome'_`db'_`year'", replace	
} /*if at least 1 ev per group for crude and adjusted models*/
} /*year from dx*/

} /* outcomes */
} /*trt type*/
}
}

log close
