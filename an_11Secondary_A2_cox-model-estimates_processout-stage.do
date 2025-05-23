capture log close
log using "$logfiles_an_dem\an_11Secondary_A2_cox-model-estimates_processout_stage.txt", replace

/*******************************************************************************
CREATE STATA FILE WITH ESTIMATES FROM CRUDE, ADJUSTED AND LATER FUP START MODELS
********************************************************************************/

cap postutil clear
tempfile results  
postfile results str8 db str8 cancersite str15 outcome str15 stage   beta sebeta using `results'

foreach db of  global databases {
foreach site in ora oes gas col liv pan lun mel bre cer ute ova pro kid bla cns thy nhl {
foreach outcome in dementia  {
foreach year in 0 {		
foreach stage in 1 2 3 4 9 {
estimates use "$results_an_dem/an_Primary_A2_cox-model-estimatesdem_stage_`site'_`outcome'_`db'_`year'"
if _rc==0  post results ("`db'") ("`site'") ("`outcome'") ("`stage'") (_b[`stage'.stage_final]) (_se[`stage'.stage_final])
} /*stage 1 to 4*/
}
}
}
}


postclose results

use `results', clear

gen hr = exp(beta)
gen lci = exp(beta-invnorm(0.975)*sebeta)
gen uci = exp(beta+invnorm(0.975)*sebeta)

save "$results_an_dem/an_Primary_A2_cox-model-estimates_processout_stage.dta", replace
list


