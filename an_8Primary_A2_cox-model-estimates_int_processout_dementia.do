capture log close
log using "$logfiles_an_dem\an_Primary_A2_cox-model-estimates_int_processout_dementia.txt", replace

/*******************************************************************************
CREATE STATA FILE WITH ESTIMATES FROM INTERACTIONS MODELS
********************************************************************************/
postutil clear
tempfile estimates
postfile estimates str10 cancer str20 outcome str20 year str20 intvar level estimate se pint using `estimates' 



foreach db of  global databases {
foreach year in 0  1 {

*depression anxiety selfharm suicide
foreach outcome in dementia  {
foreach cancer of global cancersites {

	use "$datafiles/cr_dataforanalysis_`db'_`cancer'.dta", clear 
	local year 0
	recode h_odementia .=0 
	*include "$dofiles\analyse\inc_setupadditionalcovariates.do"
	include "$dofiles\analyse_mental_health\dementia/inc_excludepriorandset_dementia.do"
	
	*Apply outcome specific exclusions
	drop if h_odementia==1
		gen calendaryearcat3 = cal_year_gp
		gen mostdeprived = (imd5==4|imd5==5)
		gen ethnicity_binary = eth5>=1
	*create new age category variable
	egen age_cat2=cut(age), at(15, 50, 65, 80, 140)
	tab age_cat2
	drop age_cat
	rename age_cat2 age_cat
	recode age_cat 15=1 50=2 65=3 80=4
	
	
*foreach intvar of any age_cat gender ethnicity_binary mostdeprived  timesincediag3 calendaryearcat3 {
foreach intvar of any age_cat  {

	*foreach intvar of any region_cat   {

global nowon "`intvar' `outcome' `cancer'"
di "$nowon"
	if "`intvar'"=="timesincediag3" {
		stsplit timesincediag3, at(0,1,2,5,100,100) 
	}
*vars


if !("`intvar'"=="gender" & ("`cancer'" == "bre" | "`cancer'" == "ova" | "`cancer'" == "ute" | "`cancer'" == "cer" | "`cancer'" == "pro")) {

local rc = 0
cap estimates use "$results/dementia/an_Primary_A2_cox-model-estimates_int`intvar'_`cancer'_`outcome'_`db'_dementia_`year'"
if _rc==0 {

if  "`intvar'"=="mostdeprived" | "`intvar'"=="ethnicity_binary"  {
local minlevel = 0
local maxlevel = 1
}
if "`intvar'"=="gender"   {
local minlevel = 1
local maxlevel = 2
}
if "`intvar'"=="calendaryearcat3"    {
local minlevel = 1
local maxlevel = 5
}
if  "`intvar'"=="age_cat"  {
local minlevel = 1
local maxlevel = 4
}


local minlevelplus1 = `minlevel'+1

local range "`minlevelplus1' (1) `maxlevel'"
if "`intvar'"=="timesincediag3" {
	local range "1 2 5"
	local force ", force"
	}

di "here 1"

cap testparm i.exposed#i.`intvar'
if _rc==0 {
local pint = r(p)	


di "here 2"

lincom 1.exposed
post estimates ("`cancer'") ("`outcome'") ("`intvar'") (0) (r(estimate)) (r(se)) (`pint') 

di "here 3"

di "`range'"
foreach i of numlist `range' {
	lincom 1.exposed+1.exposed#`i'.`intvar'
	di "here 4"
	if _rc==0 post estimates ("`cancer'") ("`outcome'") ("year'") ("`intvar'") (`i') (r(estimate)) (r(se)) (9) 
	}
}
} /*if cancers affect one sex*/
} /*if estimates exist*/
} /*intvars*/
} /*outcomes*/
} /*cancers*/
} /*year*/

postclose estimates

use `estimates', clear

gen hr = exp(estimate)
gen lci = exp(estimate-invnorm(0.975)*se)
gen uci = exp(estimate+invnorm(0.975)*se)
replace pint = . if pint==9

save "$results_dem\an_Primary_A2_cox-model-estimates_int_processout_`db'_dementia.dta", replace
list 
} /*db*/
capture log close


