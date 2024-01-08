capture log close
log using "$logfiles_an_dem\an_Primary_A2_cox-model-estimates_processout_dementia.txt", replace

/*******************************************************************************
CREATE STATA FILE WITH ESTIMATES FROM CRUDE, ADJUSTED AND HYPERTENSION / ALCOHOL
SENSITIVITY MODELS
********************************************************************************/

cap postutil clear
tempfile results  
postfile results str8 db str8 cancersite str15 outcome str15 year str8 ca beta sebeta using `results'

foreach db of  global databases {
foreach cancersite of global cancersites {
foreach outcome in dementia vasc alz other_dem ns_dem  dementiadrugs dementiahes {
foreach model of any crude agesex_adj adjusted  {
foreach year in 0  {


cap estimates use "$results_an_dem/an_Primary_A2_cox-model-estimates_`model'_`cancersite'_`outcome'_`db'_`outcome'_`year'"
if _rc==0 post results ("`db'") ("`cancersite'") ("`outcome'") ("`year'")  ("`model'") (_b[exposed]) (_se[exposed])

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

save "$results_an_dem\an_Primary_A2_cox-model-estimates_processout_dementia.dta", replace
list


/*
br db cancersite outcome ca hr lci uci if outcome=="coronary"
*/
