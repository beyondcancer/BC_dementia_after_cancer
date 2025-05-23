cap log close
log using "$logfiles_an_dem/an_Primary_A1_crude-incidence_nofailures.txt", replace t

/*******************************************************************************
CREATE FILE WITH CRUDE INCIDENCE RATES AND NUMBER OF FAILURES
*******************************************************************************/
*vasc alz other_dem ns_dem
foreach outcome in dementia   {
postutil clear
postfile failures str10 db str5 cancersite str5 year str20 outcome ncancer nfail expfail unexpfail exptime unexptime rateexp rateunexp using "$results_an_dem/an_Primary_A1_crude-incidence_nofailures_`outcome'", replace

foreach db of  global databases {
foreach cancersite of global cancersites {
foreach year in 0 1 3 5  {
noi di "`cancersite'" "`outcome'"
	use "$datafiles_an_dem/cr_dataforDEManalysis_`db'_`cancersite'.dta", clear
	
	*Apply outcome specific exclusions
	drop if h_odementia==1

	*dib "`cancersite' `outcome' `db'", stars

	*include "$Dodir/analyse_mental_health\inc_setupadditionalcovariates.do"
	include "$dofiles_an_dem/inc_excludepriorandset_dementia.do"
	
	count if exposed==1
	local ncancer=`r(N)'
	stptime
	local failures = r(failures)
	stptime if exposed==1
	local exptime=r(ptime)
	local rateexp = r(rate)
	stptime if exposed==0
	local unexptime=r(ptime)
	local rateunexp = r(rate)
	count if exposed == 1 & _d==1
	local exposedfailures = `r(N)'
	count if exposed == 0 & _d==1
	local controlfailures = `r(N)'
	post failures ("`db'") ("`cancersite'") ("`year'") ("`outcome'") (`ncancer') (`failures') (`exposedfailures') (`controlfailures') (`exptime') (`unexptime') (`rateexp') (`rateunexp')
} /* outcomes */
} /* sites */
postclose failures
} /* gold/aurum */
}

use "$results_an_dem/an_Primary_A1_crude-incidence_nofailures_dementia", clear
foreach outcome in vasc alz other_dem ns_dem  {
append using "$results_an_dem/an_Primary_A1_crude-incidence_nofailures_`outcome'"
}
sort cancer outcome
save "$results_an_dem/an_Primary_A1_crude-incidence_nofailures_ALLTYPES", replace
log close

collapse (sum) expfail unexpfail, by(outcome)
egen total_exp=total(expfail)
egen total_unexp=total(unexpfail)
gen percent_exp=(expfail/total_exp)*100
gen percent_uexp=(unexpfail/total_unexp)*100

