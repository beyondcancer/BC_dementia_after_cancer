cap log close
args cancersite db
log using "$logfiles_an_dem/an_20_cox-model-sensitivity-analyses4-stroke.txt", replace t

/***** COX MODEL ESTIMATES FOR CRUDE, ADJUSTED AND SENSITIVITY ANALYSES ****/
foreach db of  global databases {
	foreach cancersite of global cancersites {
		* 
foreach outcome in dementia  {
			foreach year in 0 {		
	use "$datafiles_an_dem/cr_dataforDEManalysis_`db'_`cancersite'.dta", clear 
	tab exposed	
	*Apply outcome specific exclusions
	drop if h_odementia==1
	*dib "`cancersite' `outcome' `db'", stars

	*include "$Dodir\analyse\inc_setupadditionalcovariates.do" /*defines female and site specific covariates*/
	
	include "$dofiles_an_dem/inc_excludepriorandset_dementia.do" /*excludes prior specific outcomes and st sets data*/
	replace dof_stroke=. if dof_stroke>=doexit
	sum dof_stroke
	stsplit stroke, after(dof_stroke) at(0)
	replace stroke = stroke + 1
	replace stroke=0 if dof_stroke==.
	*br e_patid cancer exposed stroke doentry doexit dof_stroke _*
	
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
	
	*Accounting for matching
	stcox exposed, strata(set) iterate(1000)
	 stcox exposed $covariates_common stroke, strata(set) iterate(1000) 
	  
	if _rc==0 estimates save "$results_an_dem/an_Sense_stroke_cox-model-estimates_adjusted_`cancersite'_`outcome'_`db'_`year'", replace  	 

	 
} /*if at least 1 ev per group for crude and adjusted models*/
} /*outcome*/
} /*year from dx*/
	
}	
	
} /*if at least 10 ev per group for crude and adjusted models*/

log close
