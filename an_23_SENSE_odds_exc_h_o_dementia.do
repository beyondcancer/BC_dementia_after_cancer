*an_SENSE_odds_exc_h_o_dementia


foreach db of  global databases {
	foreach cancersite of global cancersites {
		* dementiaspec vasc alz other_dem ns_dem

		use "$datafiles_an_dem/cr_dataforSENSE_DEManalysis_`db'_`cancersite'.dta", clear 

tab exposed
tab h_odementia exposed, col chi
count if exposed==1
local tot_exp=r(N)
count if exposed==0
local tot_unexp=r(N)

count if exposed==1 & h_odementia==1
local n_exp_`cancersite'=r(N)
count if exposed==0 & h_odementia==1
local n_unexp_`cancersite'=r(N)

local pct_exp_`cancersite'=(`n_exp_`cancersite''/`tot_exp')*100
local pct_unexp_`cancersite'=(`n_unexp_`cancersite''/`tot_unexp')*100

logistic h_odementia exposed 

logistic h_odementia exposed $covariates_common age gender
	if _rc==0 estimates save "$results_an_dem/an_SENSE_h_o_`cancersite'_`outcome'_`db'", replace	

	}
}

/*******************************************************************************
CREATE STATA FILE WITH ESTIMATES 
********************************************************************************/

cap postutil clear
tempfile results  
postfile results str8 db str8 cancersite ncancer pctcancer ncontrol pctcontrol beta sebeta using `results'

foreach db of  global databases {
foreach cancersite of global cancersites {

cap estimates use "$results_an_dem/an_SENSE_h_o_`cancersite'__`db'",
if _rc==0 post results ("`db'") ("`cancersite'") (`n_exp_`cancersite'') (`pct_exp_`cancersite'') (`n_unexp_`cancersite'') (`pct_unexp_`cancersite'') (_b[exposed]) (_se[exposed])

}
}

postclose results

use `results', clear

gen or = exp(beta)
gen lci = exp(beta-invnorm(0.975)*sebeta)
gen uci = exp(beta+invnorm(0.975)*sebeta)
gen result  = string(or, "%9.2fc") + " (" + string(lci, "%9.2fc") + "-" + string(uci, "%9.2fc") + ")"

save "$results_an_dem\an_SENSE_odds_exc_h_o_dementia.dta", replace
list


/*
br db cancersite outcome ca hr lci uci if outcome=="coronary"
*/
