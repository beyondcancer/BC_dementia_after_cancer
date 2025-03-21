*an_SENSE_odds_exc_h_o_dementia


foreach db of  global databases {
	foreach cancersite of global cancersites {
		* dementiaspec vasc alz other_dem ns_dem
local outcome dementia
		use "$datafiles_an_dem/cr_dataforSENSE_histdem_DEManalysis_`db'_`cancersite'.dta", clear 
tab exposed
recode h_odementia .=0
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

egen age_cat_dementia=cut(age), at(17 50 60 70 80 200)
recode age_cat_dementia 17=1 50=2 60=3 70=4 80=5
lab define age_cat_dementia 1 "18-49" 2 "50-59" 3 "60-69" 4 "70-79" 5 "80+"
lab val age_cat_dementia age_cat_dementia
tab age_cat_dementia

tab h_odementia exposed, col
tab h_odementia, miss

logistic h_odementia exposed
logistic h_odementia exposed i.age_cat_dementia $covariates_common
  
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

cap estimates use "$results_an_dem/an_SENSE_h_o_`cancersite'_dementia_`db'",
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
use "$results_an_dem\an_SENSE_odds_exc_h_o_dementia.dta", clear
list


/*
br db cancersite outcome ca hr lci uci if outcome=="coronary"
*/
