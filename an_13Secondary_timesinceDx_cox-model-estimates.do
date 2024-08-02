cap log close
args  db site
log using "$logfiles_an_dem/an_13Secondary_timesinceDx_cox-model-estimates_dementia.txt", replace t

/***** COX MODEL ESTIMATES FOR CRUDE, ADJUSTED AND SENSITIVITY ANALYSES ****/
foreach db of  global databases {
	postutil clear
postfile failures str10 db str5 cancersite str5 year str20 outcome nfail expfail unexpfail rateexp rateunexp using "$results_an_dem/an_Secondary_timesinceDx_cox_absolute_numbers", replace
	foreach site of global cancersites {
	foreach outcome in dementia {
	foreach year in 0.25 0.5 0.75 1 2 5 10 25 100 {		
	use "$datafiles_an_dem/cr_dataforDEManalysis_`db'_`site'.dta", clear 
	
	*Apply outcome specific exclusions
	drop if h_odementia==1
	di  "`cancersite' `outcome' `db'"
	
	*drop individuals with outcome event prior to index date and create stset variables
	drop if main0_date`outcome' <= indexdate
	rename indexdate doentry

	gen end_censor=	doentry+(365.25*`year')	
	gen doexit = min(doendcprdfup, end_censor, main0_date`outcome', d(29mar2021))
	format doexit %dD/N/CY
	drop if doentry == doexit /*NEW 21/09/18*/

	
*Censor controls at date of censor in cases
gen censordatecancer_temp=doexit if exposed==1
bysort setid: egen censordatecancer=max(censordatecancer_temp)
replace doexit = censordatecancer if doexit>censordatecancer

*Censor cases at date of all cases censored
gsort setid -exposed -doexit
gen censordatecontrol_temp=doexit if exposed==0
bysort setid: egen censordatecontrol=max(censordatecontrol_temp)
gen flag=1 if doexit>censordatecontrol
list setid exposed doexit censordatecontrol  if flag==1 
replace doexit = censordatecontrol if doexit>censordatecontrol
format censordatecontrol %td

	
	gen `outcome' = 1 if main0_date`outcome' <= doexit

		
	*create unique id value to account for patients who are both in the control and control groups
	sort e_patid exposed
	gen id = _n
	stset doexit, id(id) failure(`outcome' = 1) enter(doentry) origin(doentry) exit(doexit) scale(365.25)
	
	*Generate n outcomes and IRs and post to file
	stptime
	local failures = r(failures)
	stptime if exposed==1
	local rateexp = r(rate)
	stptime if exposed==0
	local rateunexp = r(rate)
	count if exposed == 1 & _d==1
	local exposedfailures = `r(N)'
	count if exposed == 0 & _d==1
	local controlfailures = `r(N)'
	post failures ("`db'") ("`site'") ("`year'") ("`outcome'") (`failures') (`exposedfailures') (`controlfailures') (`rateexp') (`rateunexp')
	
	
	
	*** CRUDE AND ADJUSTED MODELS
	*Only run models if there are >=1 failures in both groups
	count if exposed == 1 & _d==1
	local exposedfailures = `r(N)'
	count if exposed == 0 & _d==1
	local controlfailures = `r(N)'
	if `exposedfailures' >=1 & `controlfailures' >=1 {

		cap noi stcox exposed 
	if _rc==0 estimates save "$results_an_dem/an_Secondary_timesinceDx_cox-model-crude-estimates_`site'_`outcome'_`db'_`year'", replace
	cap noi stcox exposed $covariates_common, strata(set) iterate(1000)
	if _rc==0 estimates save "$results_an_dem/an_Secondary_timesinceDx_cox-model-estimates_`site'_`outcome'_`db'_`year'", replace
	 
	}
} /*if at least 1 ev per group for crude and adjusted models*/
} /*year from dx*/
} /*cancers*/
postclose failures
} /*dbs*/

use "$results_an_dem/an_Secondary_timesinceDx_cox_absolute_numbers", clear
list 
