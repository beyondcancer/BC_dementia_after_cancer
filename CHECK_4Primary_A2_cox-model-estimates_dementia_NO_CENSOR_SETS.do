cap log close
args cancersite db
log using "$logfiles_an_dem/CHECK_4Primary_A2_cox-model-estimates_dementia_NO_CENSOR_SETS.txt", replace t

/***** COX MODEL ESTIMATES FOR CRUDE, ADJUSTED AND SENSITIVITY ANALYSES ****/
foreach db of  global databases {
	foreach cancersite of global cancersites_lun {
		* 
foreach outcome in dementia  {
			foreach year in 0 {		
	use "$datafiles_an_dem/cr_dataforDEManalysis_`db'_`cancersite'.dta", clear 
	tab exposed	
	*Apply outcome specific exclusions
	drop if h_odementia==1
	*dib "`cancersite' `outcome' `db'", stars

	*include "$Dodir\analyse\inc_setupadditionalcovariates.do" /*defines female and site specific covariates*/
	
	include "$dofiles_an_dem/inc_excludepriorandset_dementia_NOCENSOR_SETS.do" /*excludes prior specific outcomes and st sets data*/
	
	*** CRUDE AND ADJUSTED MODELS
	*Only run models if there are >=10 failures in both groups
	count if exposed == 1 & _d==1
	local exposedfailures = `r(N)'
	count if exposed == 0 & _d==1
	local controlfailures = `r(N)'
	strate if exposed==1, per(1000)
	strate if exposed==0, per(1000)
	if `exposedfailures' >=10 & `controlfailures' >=10 {
 
	/*Not accounting for matching 
	stcox exposed
 stcox exposed age i.gender $covariates_common
	*/
	*Age (years)
egen age_cat_dementia=cut(age), at(17 50 60 70 80 200)
recode age_cat_dementia 17=1 50=2 60=3 70=4 80=5
lab define age_cat_dementia 1 "18-49" 2 "50-59" 3 "60-69" 4 "70-79" 5 "80+"
lab val age_cat_dementia age_cat_dementia
	
	*Accounting for matching
	stcox exposed
	stcox exposed i.age_cat_dementia
	stcox exposed age
	*generate age splines
*Restricted cubic splines
gen age_whole=floor(age) 
cap drop _S*
mkspline _S = age_whole, cubic knots(26 49 55 61 71 84 90)
	
	stcox exposed _S*
	stcox exposed $covariates_common i.age_cat_dementia i.gender
	  stop 
	if _rc==0 estimates save "$results_an_dem/CHECK_4Primary_A2_cox-model-estimates_dementia_NO_CENSOR_SETS`cancersite'_`outcome'_`db'_`year'", replace	
	 

	 
} /*if at least 1 ev per group for crude and adjusted models*/
} /*outcome*/
} /*year from dx*/
	
}	
	
} /*if at least 10 ev per group for crude and adjusted models*/

log close
