cap log close
args cancersite db
log using "$logfiles_an_dem/an_Primary_A2_cox-model-estimates_dementia_sensitivity.txt", replace t

/***** COX MODEL ESTIMATES FOR SENSITIVITY ANALYSES ****/
foreach db of  global databases {
	foreach site of global cancersites {
	foreach outcome in dementia  {
	foreach year in 0 {		
	use "$datafiles_an_dem/cr_dataforDEManalysis_`db'_`site'.dta", clear 
		
	*Apply outcome specific exclusions: already excluded, but a saftey check!
	drop if h_odementia==1
	dib "`cancersite' `outcome' `db'", stars

	*include "$Dodir\analyse\inc_setupadditionalcovariates.do" /*defines female and site specific covariates*/
	include "$dofiles_an_dem/inc_excludepriorandset_dementia.do" /*excludes prior specific outcomes and st sets data*/
	
	*** CRUDE AND ADJUSTED MODELS
	*Only run models if there are >=10 failures in both groups
	count if exposed == 1 & _d==1
	local exposedfailures = `r(N)'
	count if exposed == 0 & _d==1
	local controlfailures = `r(N)'
	strate if exposed==1, per(1000)
	strate if exposed==0, per(1000)
	if `exposedfailures' >=10 & `controlfailures' >=10 {
	
	*****Sensitivity analyses*****
	
	*Adj for ethnicity
	cap noi stcox exposed $covariates_common i.eth5_comb, strata(set) iterate(1000)
	if _rc==0 estimates save "$results_an_dem/an_Sense_ethnicity_cox-model-estimates_adjusted_`site'_`outcome'_`db'_`year'", replace	
	
	*Adj for bmi
	cap noi stcox exposed $covariates_common i.bmi_cat, strata(set) iterate(1000)
	if _rc==0 estimates save "$results_an_dem/an_Sense_bmi_cox-model-estimates_adjusted_`site'_`outcome'_`db'_`year'", replace	
	
	*Excluding no consulters in year prior to index
	cap noi stcox exposed $covariates_common if b_nocons_yrprior_gr!=0, strata(set) iterate(1000)
	if _rc==0 estimates save "$results_an_dem/an_Sense_exc_non_cons_cox-model-estimates_adjusted_`site'_`outcome'_`db'_`year'", replace

	/*don't include those having chemo: THIS WAS INCORRECT - it didn't remove those who died/were lost to follow-up in first year
	drop if doentry<=d(01apr2014)
	tab exposed
	gen exposed_trt=exposed
	replace exposed_trt=2 if exposed==1 & dof_chemo!=.
	tab exposed_trt
	replace exposed_trt=1 if (dof_chemo<doentry-31 | dof_chemo>doentry+365.25) & exposed==1
	replace exposed_trt=1 if dof_chemo>doendcprdfup & exposed==1
	tab exposed_trt 
	drop if exposed_trt==2
	
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
	
	cap noi stcox exposed $covariates_common, strata(set) iterate(1000)
	if _rc==0 estimates save "$results_an_dem/an_Sense_nochemo_cox-model-estimates_adjusted_`site'_`outcome'_`db'_`year'", replace	
	*/
 
} /*if at least 1 ev per group for crude and adjusted models*/
} /*outcome*/
} /*year from dx*/
}	
} /*if at least 10 ev per group for crude and adjusted models*/

log close
