cap log close
log using "$logfiles_an_dem/an_Primary_A1_crude-incidence_nofailures.txt", replace t

/*******************************************************************************
CREATE FILE WITH CRUDE INCIDENCE RATES AND NUMBER OF FAILURES
*******************************************************************************/
*
foreach outcome in dementia dementiaspec vasc alz other_dem ns_dem  {
postutil clear
postfile failures str10 db str5 cancersite str5 year str20 outcome nfail expfail unexpfail rateexp rateunexp using "$results_an_dem/an_Primary_A1_crude-incidence_nofailures_`outcome'", replace

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
	count if exposed == 1 & _d==1
	local exposedfailures = `r(N)'
	count if exposed == 0 & _d==1
	local controlfailures = `r(N)'
	post failures ("`db'") ("`cancersite'") ("`year'") ("`outcome'") (`failures') (`exposedfailures') (`controlfailures') (`rateexp') (`rateunexp')
} /* outcomes */
} /* sites */
postclose failures
} /* gold/aurum */
}

use "$results_an_dem/an_Primary_A1_crude-incidence_nofailures_dementia", clear
append using "$results_an_dem/an_Primary_A1_crude-incidence_nofailures_dementiadrugs"
sort cancer outcome
list

log close

