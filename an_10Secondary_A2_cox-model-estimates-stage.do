cap log close
args  db site
log using "$logfiles_an_dem/an_Primary_A2_cox-model-estimates_dementia_stage.txt", replace t

/***** COX MODEL ESTIMATES FOR CRUDE, ADJUSTED AND SENSITIVITY ANALYSES ****/
foreach db of  global databases {
	foreach site of global cancersites {
	foreach outcome in dementia {
	di "`site'"    
	foreach year in 0 {		
	use "$datafiles_an_dem/cr_dataforDEManalysis_`db'_`site'.dta", clear 
	
	drop if index_year<2012
	
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
	if "`site'"=="bre" | "`site'"=="ova" | "`site'"=="bla" | "`site'"=="bre" | "`site'"=="cer" | "`site'"=="col" | "`site'"=="gas" | "`site'"=="kid" | "`site'"=="liv" | "`site'"=="lun" | "`site'"=="mel" | "`site'"=="oes" | "`site'"=="ora" | "`site'"=="ova" | "`site'"=="pan" | "`site'"=="pro" | "`site'"=="thy" | "`site'"=="ute" {
	local stage stage_tnm
	}
	
	replace `stage'=0 if  `stage'==.
	replace `stage'=. if `stage'==99 
	tab `stage'
	tab `stage', nolab

	*Apply outcome specific exclusions
	drop if h_o365_`year'`outcome'==1
	drop if h_o`outcome'==1
	noi di "***************`site' `outcome' `db'********************"
	
	*include "$Dodir\analyse\inc_setupadditionalcovariates.do" /*defines female and site specific covariates*/
	include "$dofiles_an_dem/inc_excludepriorandset_dementia.do" /*excludes prior specific outcomes and st sets data*/
	tab `stage'
	rename `stage' stage_final

	*** CRUDE AND ADJUSTED MODELS
	*Only run models if there are >=1 failures in both groups
	count if stage_final == 4 & _d==1
	local exposed_stage4 = `r(N)'
	count if stage_final == 3 & _d==1
	local exposed_stage3 = `r(N)'
	count if stage_final == 2 & _d==1
	local exposed_stage2 = `r(N)'
	count if stage_final == 1 & _d==1
	local exposed_stage1 = `r(N)'
	count if stage_final == 0 & _d==1
	local controlfailures = `r(N)'

*	if `exposed_trtfailures' >=1 & `controlfailures' >=1 & `exposed_trtfailures2' >=1 {
	cap noi stcox i.stage_final $covariates_common, strata(set) iterate(1000)
	if _rc==0 estimates save "$results_an_dem/an_Primary_A2_cox-model-estimatesdem_stage_`site'_`outcome'_`db'_`year'", replace	
*} /*if at least 1 ev per group for crude and adjusted models*/
} /*year from dx*/
} /* outcomes */
}
}

log close
