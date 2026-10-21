*Combine balance summary info into one file and drop the multiples
clear
foreach cancertype of any bla bre cer col cns gas kid leu liv lun mel mye nhl oes ora ova pan pro thy ute{
	confirm file "$results_an_dem/hpc_output/results/an_cdekm_BalanceSummary_`cancertype'.dta"
	append using "$results_an_dem/hpc_output/results/an_cdekm_BalanceSummary_`cancertype'"
}
confirm var cancertype
save "$results_an_dem/hpc_output/results/an_cdekm_BalanceSummary", replace

foreach cancertype of any bla bre cer col cns gas kid leu liv lun mel mye nhl oes ora ova pan pro thy ute{
	erase "$results_an_dem/hpc_output/results/an_cdekm_BalanceSummary_`cancertype'.dta"
}

*Combine bootstrap reps into one file and drop the multiples (including the hpc splits into blocks)
**A. drop the blocks
foreach cancertype of any bla bre cer col cns gas kid leu liv lun mel mye nhl oes ora ova pan pro thy ute {
	confirm file "$results_an_dem/hpc_output/results/an_cdekm_bootstraps_`cancertype'.dta"
	use "$results_an_dem/hpc_output/results/an_cdekm_bootstraps_`cancertype'.dta", clear
	count
	assert _N==500
	forvalues i=1/20{
		cap erase "$results_an_dem/hpc_output/results/an_cdekm_bootstraps_`cancertype'_b`i'.dta"
	}
}
**B. combine all cancers
clear
foreach cancertype of any bla bre cer col cns gas kid leu liv lun mel mye nhl oes ora ova pan pro thy ute{
	confirm file "$results_an_dem/hpc_output/results/an_cdekm_Bootstraps_`cancertype'.dta"
	append using "$results_an_dem/hpc_output/results/an_cdekm_Bootstraps_`cancertype'.dta"
	if "`cancertype'"=="bla" gen str3 cancertype = "`cancertype'"
	else replace cancertype = "`cancertype'" if cancertype==""
	order cancertype
}
count 
save "$results_an_dem/hpc_output/results/an_cdekm_Bootstraps", replace
**C. delete the multiples
foreach cancertype of any bla bre cer col cns gas kid leu liv lun mel mye nhl oes ora ova pan pro thy ute{
	confirm file "$results_an_dem/hpc_output/results/an_cdekm_Bootstraps.dta"
	use "$results_an_dem/hpc_output/results/an_cdekm_Bootstraps.dta", clear
	cou
	assert _N==10000
	forvalues i=1/20{
		cap erase "$results_an_dem/hpc_output/results/an_cdekm_bootstraps_`cancertype'.dta"
	}
}

*Combine the curve info into one file
clear
foreach cancertype of any bla bre cer col cns gas kid leu liv lun mel mye nhl oes ora ova pan pro thy ute{
	confirm file "$results_an_dem/hpc_output/results/an_cdekm_Curve_`cancertype'.dta"
	append using "$results_an_dem/hpc_output/results/an_cdekm_Curve_`cancertype'.dta"
}
confirm var cancertype
save "$results_an_dem/hpc_output/results/an_cdekm_Curve", replace

foreach cancertype of any bla bre cer col cns gas kid leu liv lun mel mye nhl oes ora ova pan pro thy ute{
	erase "$results_an_dem/hpc_output/results/an_cdekm_Curve_`cancertype'.dta"
}	

*Combine the estimates and CIs into one file
clear
foreach cancertype of any bla bre cer col cns gas kid leu liv lun mel mye nhl oes ora ova pan pro thy ute{
	confirm file "$results_an_dem/hpc_output/results/an_cdekm_EstimatesAndBSCIs_`cancertype'.dta"
	append using "$results_an_dem/hpc_output/results/an_cdekm_EstimatesAndBSCIs_`cancertype'.dta"
}
confirm var cancertype
save "$results_an_dem/hpc_output/results/an_cdekm_EstimatesAndBSCIs", replace
count
assert _N==560

foreach cancertype of any bla bre cer col cns gas kid leu liv lun mel mye nhl oes ora ova pan pro thy ute{
	erase "$results_an_dem/hpc_output/results/an_cdekm_EstimatesAndBSCIs_`cancertype'.dta"
	erase "$results_an_dem/hpc_output/results/an_cdekm_PointEstimates_`cancertype'.dta"
}	

*Combine the Weighted Cox estimates into one file
clear
foreach cancertype of any bla bre cer col cns gas kid leu liv lun mel mye nhl oes ora ova pan pro thy ute{
	confirm file "$results_an_dem/hpc_output/results/an_WeightedCox_Estimates_`cancertype'.dta"
	append using "$results_an_dem/hpc_output/results/an_WeightedCox_Estimates_`cancertype'.dta"
}
confirm var cancertype
save "$results_an_dem/hpc_output/results/an_WeightedCox_Estimates", replace
count
assert _N==80

foreach cancertype of any bla bre cer col cns gas kid leu liv lun mel mye nhl oes ora ova pan pro thy ute{
	erase "$results_an_dem/hpc_output/results/an_WeightedCox_Estimates_`cancertype'.dta"
}	
