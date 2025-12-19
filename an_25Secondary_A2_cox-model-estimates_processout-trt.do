capture log close
log using "$logfiles_an_dem\an_Primary_A2_cox-model-estimates_processout_trt_dementia.txt", replace

/*******************************************************************************
CREATE STATA FILE WITH ESTIMATES FROM CRUDE, ADJUSTED AND LATER FUP START MODELS
********************************************************************************/

cap postutil clear
tempfile results  
postfile results str8 db str8 cancersite str15 outcome str15 trt str15 exposed str8 model beta sebeta using `results'

foreach db of  global databases {
foreach cancersite of global cancersites {
foreach outcome in dementia {
foreach model in adj adjstage  {
foreach year in 1   {		
	foreach trt in chemo radio surgopcs surgcr {
foreach exposed in 1 2 {

cap estimates use "$results_an_dem\an_Primary_A2_cox-model-estimates_`model'_`trt'_`cancersite'_`outcome'_`db'_`year'"
if _rc==0 post results ("`db'") ("`cancersite'") ("`outcome'") ("`trt'") ("`exposed'")  ("`model'") (_b[`exposed'.exposed]) (_se[`exposed'.exposed])
}
}
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

save "$results_an_dem\an_Primary_A2_cox-model-estimates_processout_trt_dementia.dta", replace



