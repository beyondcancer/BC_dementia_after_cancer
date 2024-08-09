cap log close
log using "$logfiles_an_dem/an_7Primary_A2_rawnumbers_int_dementia.txt", replace t

/*******************************************************************************
CREATE FILE WITH CRUDE INCIDENCE RATES AND NUMBER OF FAILURES
*******************************************************************************/

postutil clear
postfile failures str10 db str5 cancersite str20 outcome str20 year str20 intvar level nfail nfailexp nfailunexp rateexp rateunexp using "$results_an_dem/an_7Primary_A2_rawnumbers_int_dementia", replace

foreach db of global databases {
foreach cancersite of global cancersites {
foreach outcome in dementia {
foreach year in 0  {		

	use "$datafiles_an_dem/cr_dataforDEManalysis_`db'_`cancersite'.dta", clear 

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


if  "`intvar'"=="mostdeprived" |  "`intvar'"=="b_cvd" {
local minlevel = 0
local maxlevel = 1
}
if "`intvar'"=="gender"   {
local minlevel = 1
local maxlevel = 2
}
if "`intvar'"=="age_cat_dementia"   {
local minlevel = 0
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


local range "`minlevel' (1) `maxlevel'"
di "`range'"

foreach i of numlist `range' {
	*include "$Dodir/analyse_mental_health\inc_setupadditionalcovariates.do"
	
	stptime
	local failures = r(failures)
	cap stptime if exposed==1 & `intvar'==`i'
	if _rc==0 {
	local failuresexp = r(failures)
	local rateexp = r(rate)
	}
	cap stptime if exposed==0 & `intvar'==`i'
	if _rc==0 {
	local failuresunexp = r(failures)
	local rateunexp = r(rate)
	post failures ("`db'") ("`cancersite'") ("`outcome'") ("`year'") ("`intvar'") (`i') (`failures') (`failuresexp') (`failuresunexp')  (`rateexp') (`rateunexp')
	}
	}


} /*intvar*/
} /* year*/ 
} /* outcomes */
} /* sites */
} /* gold/aurum */
}
postclose failures
