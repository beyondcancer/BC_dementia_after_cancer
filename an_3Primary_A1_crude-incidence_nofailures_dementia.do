cap log close
log using "$logfiles_an_dem/an_Primary_A1_crude-incidence_nofailures.txt", replace t

/*******************************************************************************
CREATE FILE WITH CRUDE INCIDENCE RATES AND NUMBER OF FAILURES
*******************************************************************************/
*dementia vasc alz other_dem ns_dem
foreach outcome in dementia vasc alz other_dem ns_dem  dementiadrugs dementiahes {
postutil clear
postfile failures str10 db str5 cancersite str5 year str20 outcome nfail rateexp rateunexp using "$results_an_dem/an_Primary_A1_crude-incidence_nofailures_`outcome'", replace

foreach db of  global databases {
foreach cancersite of global cancersites {
foreach year in 0  {
noi di "`cancersite'" "`outcome'"
	use "$datafiles_an_dem/cr_dataforDEManalysis_`db'_`cancersite'.dta", clear
	
	*Apply outcome specific exclusions
	drop if h_odementia==1
	drop if h_o365_`year'dementia==1

	dib "`cancersite' `outcome' `db'", stars

	*include "$Dodir/analyse_mental_health\inc_setupadditionalcovariates.do"
	include "$dofiles_an_dem/inc_excludepriorandset_dementia.do"
	
	stptime
	local failures = r(failures)
	stptime if exposed==1
	local rateexp = r(rate)
	stptime if exposed==0
	local rateunexp = r(rate)
	post failures ("`db'") ("`cancersite'") ("`year'") ("`outcome'") (`failures') (`rateexp') (`rateunexp')
} /* outcomes */
} /* sites */
postclose failures
} /* gold/aurum */
}


use "$results_an_dem/an_Primary_A1_crude-incidence_nofailures_dementia", clear
list
use "$results_an_dem/an_Primary_A1_crude-incidence_nofailures_dementiahes", clear
list
log close

