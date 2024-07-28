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
foreach outcome in dementia {
foreach model of any dementiaspec exc_non_cons ethnicity bmi pandemic nochemo {
foreach year in 0 {


cap estimates use "$results_an_dem/an_Sense_`model'_cox-model-estimates_adjusted_`cancersite'_`outcome'_`db'_0"

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

save "$results_an_dem\an_Primary_A2_cox-model-estimates_processout_dementia-sensitivity.dta", replace
list


/*
br db cancersite outcome ca hr lci uci if outcome=="coronary"
*/
