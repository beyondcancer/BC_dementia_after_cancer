cap log close
args cancersite db
log using "$logfiles_an_dem/an_Primary_A2_cox-model-estimates_dementia_sensitivity_downs.txt", replace t

/***** COX MODEL ESTIMATES FOR SENSITIVITY ANALYSES ****/
foreach db of  global databases {
	foreach site of global cancersites {
	foreach outcome in dementia  {
	foreach year in 0 {		
	use "$datafiles_an_dem/cr_dataforDEManalysis_`db'_`site'.dta", clear 
		
	*Apply outcome specific exclusions: already excluded, but a saftey check!
	drop if h_odementia==1
	*dib "`cancersite' `outcome' `db'", stars

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
	
	*Drop those with downs syndrome
	tab downs_syndrome exposed, col
	drop if downs_syndrome==1
	cap noi stcox exposed $covariates_common, strata(set) iterate(1000)
	if _rc==0 estimates save "$results_an_dem/an_Sense_downs_cox-model-estimates_adjusted_`site'_`outcome'_`db'_`year'", replace	
	
} /*if at least 1 ev per group for crude and adjusted models*/
} /*outcome*/
} /*year from dx*/
}	
} /*if at least 10 ev per group for crude and adjusted models*/

log close
