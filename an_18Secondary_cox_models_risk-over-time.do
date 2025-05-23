
capture log close
log using "$logfiles_an_dem\an_18Secondary_cox_models_risk-over-time", replace

 tempname myhandle
   file open `myhandle' using "$results_an_dem/an_218_cox_model_phtest_restartfup.txt", write  replace 

qui {
	foreach site of global cancersites {
foreach db of  global databases {

	foreach outcome of global outcomes {

	****START FOLLOW_UP LATER
	*foreach year in 0 1 3 5 10 {		
	foreach year in  1 {		
	use "$datafiles_an_dem/cr_dataforDEManalysis_`db'_`site'.dta", clear 

	dib "`site' `outcome' `db'", stars
	
	*Apply outcome specific exclusions: already excluded, but a saftey check!
	drop if h_odementia==1
	noi dib "`site' `outcome' `db'", stars

	*include "$Dodir\analyse\inc_setupadditionalcovariates.do" /*defines female and site specific covariates*/
	include "$dofiles_an_dem\inc_excludepriorandset_dementia.do" /*excludes prior specific outcomes and st sets data*/
	tab exposed
	*** CRUDE AND ADJUSTED MODELS
	*Only run models if there are >=1 failures in both groups
	count if exposed == 1 & _d==1
	local exposedfailures = `r(N)'
	count if exposed == 0 & _d==1
	local controlfailures = `r(N)'
	if `exposedfailures' >=1 & `controlfailures' >=1 {
	
	cap noi stcox exposed, strata(set) iterate(1000)
	if _rc==0 estimates save "$results_an_dem/an_18Secondary_cox_models_risk_over_time_crude_`site'_`outcome'_`db'_`year'", replace
	cap noi stcox exposed $covariates_common, strata(set) iterate(1000)
	if _rc==0 estimates save "$results_an_dem/an_18Secondary_cox_models_risk_over_time_adj_`site'_`outcome'_`db'_`year'", replace
	noi if e(N_fail)>0 estat phtest, d
	local phtest=`r(p)'
	file write `myhandle' _n "`site'" _tab  (`phtest') 

} /*if at least 1 ev per group for crude and adjusted models*/
} /*year from dx*/

} /* outcomes */
}
}
}

log close
