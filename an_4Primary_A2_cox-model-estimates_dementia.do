cap log close
args cancersite db
log using "$logfiles_an_dem/an_Primary_A2_cox-model-estimates_dementia.txt", replace t

/***** COX MODEL ESTIMATES FOR CRUDE, ADJUSTED AND SENSITIVITY ANALYSES ****/
foreach db of  global databases {
	foreach cancersite of global cancersites {
		* vasc alz other_dem ns_dem
foreach outcome in dementia   {
			foreach year in 0 {		
	use "$datafiles_an_dem/cr_dataforDEManalysis_`db'_`cancersite'.dta", clear 
	tab exposed	
	*Apply outcome specific exclusions
	drop if h_odementia==1
	*dib "`cancersite' `outcome' `db'", stars

	*include "$Dodir\analyse\inc_setupadditionalcovariates.do" /*defines female and site specific covariates*/
	
	include "$dofiles_an_dem/inc_excludepriorandset_dementia.do" /*excludes prior specific outcomes and st sets data*/

	
	*** CRUDE AND ADJUSTED MODELS
	*Only run models if there are >=10 failures in both groups
	count if exposed == 1 & _d==1
	local exposedfailures = `r(N)'
	count if exposed == 0 & _d==1
	count if _d==1
	local controlfailures = `r(N)'
	strate if exposed==1, per(1000)
	strate if exposed==0, per(1000)
	if `exposedfailures' >=10 & `controlfailures' >=10 {
 
	*Not accounting for matching 
	stcox exposed

	
	*Accounting for matching
	stcox exposed	
	if _rc==0 estimates save "$results_an_dem/an_Primary_A2_cox-model-estimates_unadj_`cancersite'_`outcome'_`db'_`year'", replace
	stcox exposed, strata(set) iterate(1000)
	*stcox exposed age i.gender i.index_year_gr

	if _rc==0 estimates save "$results_an_dem/an_Primary_A2_cox-model-estimates_agesex_adj_`cancersite'_`outcome'_`db'_`year'", replace
	*stcox exposed age i.gender $covariates_common i.index_year_gr
	stcox exposed $covariates_common, strata(set) iterate(1000) 
	if _rc==0 estimates save "$results_an_dem/an_Primary_A2_cox-model-estimates_adjusted_`cancersite'_`outcome'_`db'_`year'", replace	
	
	recode b_nocons_yrprior_gr 4=2 10=3

	 stcox exposed $covariates_common i.b_nocons_yrprior_gr, strata(set) iterate(1000) 
	if _rc==0 estimates save "$results_an_dem/an_Sense_adj_hcuse_cox-model-estimates_adjusted_`cancersite'_`outcome'_`db'_0", replace	
	
} /*if at least 1 ev per group for crude and adjusted models*/
} /*outcome*/
} /*year from dx*/
	
}	
	
} /*if at least 10 ev per group for crude and adjusted models*/

log close




