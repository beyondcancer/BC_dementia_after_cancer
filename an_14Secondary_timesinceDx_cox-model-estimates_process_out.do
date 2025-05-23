capture log close
log using "$logfiles_an_dem\an_14Secondary_timesinceDx_cox-model-estimates_process_out.txt", replace

/*******************************************************************************
CREATE STATA FILE WITH ESTIMATES FROM CRUDE, ADJUSTED AND HYPERTENSION / ALCOHOL
SENSITIVITY MODELS
********************************************************************************/

cap postutil clear
tempfile results  
postfile results str8 db str8 cancersite str15 outcome str15 year beta sebeta using `results'

foreach db of  global databases {
foreach cancersite of global cancersites {
foreach outcome in dementia  {
foreach year in 0.25 0.5 0.75 1 2 5 10 100 {		
cap estimates use "$results_an_dem/an_Secondary_timesinceDx_cox-model-estimates_`cancersite'_`outcome'_`db'_`year'"
if _rc==0 post results ("`db'") ("`cancersite'") ("`outcome'") ("`year'") (_b[exposed]) (_se[exposed])
}
}
}
}

postclose results

use `results', clear

gen hr = exp(beta)
gen lci = exp(beta-invnorm(0.975)*sebeta)
gen uci = exp(beta+invnorm(0.975)*sebeta)

save "$results_an_dem/an_Secondary_timesinceDx_cox_processout_dementia.dta", replace



/*
br db cancersite outcome ca hr lci uci if outcome=="coronary"
*/
