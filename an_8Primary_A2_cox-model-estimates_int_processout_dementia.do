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

*depression anxiety selfharm suicide
foreach outcome in dementia  {
foreach cancer of global cancersites {

	use "$datafiles_an_dem/cr_dataforDEManalysis_`db'_`cancer'.dta", clear 
	recode h_odementia .=0 
	*include "$dofiles\analyse\inc_setupadditionalcovariates.do"
	include "$dofiles_an_dem/inc_excludepriorandset_dementia.do"
	
	*Apply outcome specific exclusions
	drop if h_odementia==1
		gen mostdeprived = (imd5==4|imd5==5)
		gen ethnicity_binary = eth5_cprd>=1
	*create new age category variable
	egen age_cat2=cut(age), at(15, 50, 65, 80, 140)
	tab age_cat2
	drop age_cat
	rename age_cat2 age_cat
	recode age_cat 15=1 50=2 65=3 80=4
	
	gen region_cat = region
	recode region_cat 2/3=1 4=2 6=2 5=3 7=5 8/9=4
	
	egen cal_year_gp=cut(index_year), at(1998 2003 2009 2015)
	recode cal_year_gp 1998=1 2003=2 2009=3 2015=4
		gen calendaryearcat3 = cal_year_gp
	
	
foreach intvar of any age_cat gender ethnicity_binary calendaryearcat3 mostdeprived region_cat {

global nowon "`intvar' `outcome' `cancer'"
di "$nowon"

if !("`intvar'"=="gender" & ("`cancer'" == "bre" | "`cancer'" == "ova" | "`cancer'" == "ute" | "`cancer'" == "cer" | "`cancer'" == "pro")) {

local rc = 0
cap estimates use "$results_an_dem/an_Primary_A2_cox-model-estimates_int`intvar'_`cancer'_`outcome'_`db'_dementia_`year'"
if _rc==0 {

if  "`intvar'"=="mostdeprived" | "`intvar'"=="ethnicity_binary"  {
local minlevel = 0
local maxlevel = 1
}
if "`intvar'"=="gender"   {
local minlevel = 1
local maxlevel = 2
}
if "`intvar'"=="age_cat"   {
local minlevel = 1
local maxlevel = 3
}
if "`intvar'"=="calendaryearcat3" | "`intvar'"=="region_cat"   {
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

save "$results_an_dem\an_Primary_A2_cox-model-estimates_int_processout_`db'_dementia.dta", replace
list 
} /*db*/
capture log close


