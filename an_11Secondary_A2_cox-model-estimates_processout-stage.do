capture log close
log using "$logfiles_an_dem\an_Primary_A2_cox-model-estimates_processout_stage.txt", replace

/*******************************************************************************
CREATE STATA FILE WITH ESTIMATES FROM CRUDE, ADJUSTED AND LATER FUP START MODELS
********************************************************************************/

cap postutil clear
tempfile results  
postfile results str8 db str8 cancersite str15 outcome str15 stage   beta sebeta using `results'

foreach db of  global databases {
foreach site of global cancersites {
foreach outcome in dementia  {
foreach year in 0 {		
foreach stage in 1 2 3 {
estimates use "$results_an_dem/an_Primary_A2_cox-model-estimatesdem_stage_`site'_`outcome'_`db'_`year'"
if _rc==0 post results ("`db'") ("`site'") ("`outcome'") ("`stage'") (_b[`stage'.stage_final]) (_se[`stage'.stage_final])
} /*stage 1 to 3*/
if "`site'"!="mye" & "`site'"!="leu" {
if _rc==0 post results ("`db'") ("`site'") ("`outcome'") ("4") (_b[4.stage_final]) (_se[4.stage_final])
}
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


