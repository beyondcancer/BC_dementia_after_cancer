capture log close
log using "$logfiles_an_dem\an_Primary_A2_cox-model-estimates_int_processout_dementia.txt", replace

/*******************************************************************************
CREATE STATA FILE WITH ESTIMATES FROM INTERACTIONS MODELS
********************************************************************************/
postutil clear
tempfile estimates
postfile estimates str10 cancer str20 outcome str20 year str20 intvar level estimate se pint using `estimates' 



foreach db of  global databases {
foreach year in 0 {
foreach outcome in dementia  {
foreach cancer of global cancersites {

	use "$datafiles_an_dem/cr_dataforDEManalysis_`db'_`cancer'.dta", clear 
	recode h_odementia .=0 
	*include "$dofiles\analyse\inc_setupadditionalcovariates.do"
	include "$dofiles_an_dem/inc_excludepriorandset_dementia.do"
	
	*Apply outcome specific exclusions
	drop if h_odementia==1
		gen mostdeprived = (imd5==4|imd5==5)
	
*Age (years)
egen age_cat_dementia=cut(age), at(17 50 60 70 80 200)
recode age_cat_dementia 17=1 50=2 60=3 70=4 80=5
lab define age_cat_dementia 1 "18-49" 2 "50-59" 3 "60-69" 4 "70-79" 5 "80+"
lab val age_cat_dementia age_cat_dementia
	
	gen region_cat = region
	recode region_cat 2/3=1 4=2 6=2 5=3 7=5 8/9=4
	
	egen cal_year_gp=cut(index_year), at(1998 2003 2009 2015 2020)
	recode cal_year_gp 1998=1 2003=2 2009=3 2015=4
		gen calendaryearcat3 = cal_year_gp
	
	 
foreach intvar of any age_cat_dementia gender eth5_comb calendaryearcat3 mostdeprived region_cat b_cvd {
*
global nowon "`intvar' `outcome' `cancer'"
di "$nowon"

if !("`intvar'"=="gender" & ("`cancer'" == "bre" | "`cancer'" == "ova" | "`cancer'" == "ute" | "`cancer'" == "cer" | "`cancer'" == "pro")) {

local rc = 0
cap estimates use "$results_an_dem/an_Primary_A2_cox-model-estimates_int`intvar'_`cancer'_`outcome'_`db'_dementia_`year'"
if _rc==0 {
/*
if  "`intvar'"=="mostdeprived" |  "`intvar'"=="b_cvd" {
local minlevel = 0
local maxlevel = 1
}
if "`intvar'"=="gender"   {
local minlevel = 1
local maxlevel = 2
}
if "`intvar'"=="age_cat_dementia"   {
local minlevel = 1
local maxlevel = 5
}
if "`intvar'"=="calendaryearcat3" {
local minlevel = 1
local maxlevel = 4
}
if "`intvar'"=="region_cat" {
local minlevel = 1
local maxlevel = 5
}
if "`intvar'"=="eth5_comb" {
local minlevel = 0
local maxlevel = 3
}

local minlevelplus1 = `minlevel'+1

local range "`minlevelplus1' (1) `maxlevel'"
*/
cap testparm i.exposed#i.`intvar'
if _rc==0 {
local pint = r(p)	

lincom 1.exposed
post estimates ("`cancer'") ("`outcome'") ("year'") ("`intvar'") (0) (r(estimate)) (r(se)) (`pint') 

local range2 "1 2 3 4 5"

foreach i of numlist `range2' {
	cap lincom 1.exposed+1.exposed#`i'.`intvar'
	di "here 4"
	if _rc==0 post estimates ("`cancer'") ("`outcome'") ("year'") ("`intvar'") (`i') (r(estimate)) (r(se)) (`pint') 
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

drop if intvar=="age_cat_dementia" & level==0
drop if intvar=="gender" & level==0
drop if intvar=="calendaryearcat3" & level==0
drop if intvar=="region_cat" & level==0

list

save "$results_an_dem\an_Primary_A2_cox-model-estimates_int_processout_`db'_dementia.dta", replace
list 
} /*db*/
capture log close


