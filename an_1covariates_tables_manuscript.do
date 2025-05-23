cap log close
log using "$logfiles_an_dem\LOG_an_covariates_tables_manuscript.txt", text replace
********************************************************************************
* do file author:	H Forbes
* Date: 			18 January 2022
* Description: 		Creation of Table 1 descriptive statistics cancer/mh paper
********************************************************************************
* Notes on major updates (Date - description):
********************************************************************************

*******************************************************************************
*Generic code to output one row of table
cap prog drop generaterow

program define generaterow
syntax, variable(varname) condition(string) outcome(string)
	
	*put the varname and condition to left so that alignment can be checked vs shell
	file write tablecontent ("`variable'") _tab ("`condition'") _tab
	
	cou
	local overalldenom=r(N)

	cou if exposed==1 
	local coldenom = r(N)
	cou if exposed==1 & `variable' `condition'
	local pct = 100*(r(N)/`coldenom')
	file write tablecontent (r(N)) (" (") %4.1f  (`pct') (")") _tab
	
	cou if exposed==0 
	local coldenom = r(N)
	cou if exposed==0 & `variable' `condition'
	local pct = 100*(r(N)/`coldenom')
	file write tablecontent (r(N)) (" (") %4.1f  (`pct') (")") _tab _n
		
end

*******************************************************************************
*Generic code to output one section (varible) within table (calls above)
cap prog drop tabulatevariable
prog define tabulatevariable
syntax, variable(varname) start(real) end(real) [missing] outcome(string)

	foreach varlevel of numlist `start'/`end'{ 
		generaterow, variable(`variable') condition("==`varlevel'") outcome(exposed)
	}
	if "`missing'"!="" generaterow, variable(`variable') condition(">=.") outcome(exposed)

end

*******************************************************************************

*Set up output file

foreach db in aandg {
use "$datafiles_an_dem/cr_dataforDEManalysis_`db'.dta", clear

local outcome dementia
local year 0
count
recode smokstatus 12=3
drop if h_odementia==1

	include "$dofiles_an_dem/inc_excludepriorandset_dementia.do" /*excludes prior specific outcomes and st sets data*/

tab exposed 
********************************************************************************
* 2 - Prepare formats for data for output
********************************************************************************

cap file close tablecontent
file open tablecontent using "$results_an_dem\Table_an_covariates_tables_manuscript_`db'.txt", write text replace

file write tablecontent "Variable" _tab "Level" _tab "Cancer survivors" _tab "Non-cancer participants" _n

*to*totals	 
gen byte Total=1
tabulatevariable, variable(Total) start(1) end(1) outcome(exposed)

*** Person years from cancer diagnosis to the end of CPRD follow-up / study period
* follow-up for each analysis will depend on the mh event date
gen time = (doexit - doentry)/365.25
 
file write tablecontent "Person-years from cancer diagnosis/baseline to end of follow-up" _n

file write tablecontent _tab "Mean (SD)"
foreach var in  1 0 {
qui summ time if exposed == `var', d
local mean = string(r(mean), "%6.1fc")
local sd = string(r(sd), "%6.1fc")
local meanstr = "`mean'" + " (" + "`sd'" + ")"
file write tablecontent _tab ("`meanstr'")
}

file write tablecontent _n _tab "Median (IQR)"
foreach var in  1 0 {
qui summ time if exposed == `var', d
local mean = string(r(mean), "%6.1fc")
local iqrlow = string(r(p25), "%6.1fc")
local iqrhigh = string(r(p75), "%6.1fc")
local medianstr = "`mean'" + " (" + "`iqrlow'" + "-" + "`iqrhigh'" + ")"
file write tablecontent _tab ("`medianstr'")
}


file write tablecontent _n  _tab "Range"
foreach var in  1 0 {
qui summ time if exposed == `var', d
local rangemin = string(r(min), "%6.1fc")
local rangemax = string(r(max), "%6.1fc")
local rangestr = "`rangemin'" + "-" + "`rangemax'"
file write tablecontent  _tab ("`rangestr'")
}

drop time

*** Total person years included (from index to end of follow-up)
file write tablecontent _n "Total person-years included* (millions)"
gen time = (doexit - doentry)/365.25
qui summ time if exposed == 1
local timemillions = r(sum) / 1000000
local string = string(`timemillions', "%6.2fc")
file write tablecontent  _tab _tab ("`string'")

qui summ time if exposed == 0
local timemillions = r(sum) / 1000000
local string = string(`timemillions', "%6.2fc")
file write tablecontent  _tab ("`string'") _n
file write tablecontent _n 

*Age (years)
egen age_cat_dementia=cut(age), at(17 50 60 70 80 200)
recode age_cat_dementia 17=1 50=2 60=3 70=4 80=5
lab define age_cat_dementia 1 "18-49" 2 "50-59" 3 "60-69" 4 "70-79" 5 "80+"
lab val age_cat_dementia age_cat_dementia

*Age catgorical
tabulatevariable, variable(age_cat_dementia) start(1) end(5) outcome(exposed) 
file write tablecontent _n 

*Sex
tabulatevariable, variable(gender) start(1) end(2) outcome(exposed)
file write tablecontent _n 

*IMD
tabulatevariable, variable(imd5) start(1) end(5) outcome(exposed)
file write tablecontent _n 

*Ethnicity
tabulatevariable, variable(eth5_comb) start(0) end(3) missing outcome(exposed)
file write tablecontent _n 

*Year cancer diagnosis
tabulatevariable, variable(index_year_gr) start(1) end(5) outcome(exposed)
file write tablecontent _n 

*H/C contacts pre-basline
recode b_nocons_yrprior_gr 4=2 10=3
tabulatevariable, variable(b_nocons_yrprior_gr) start(0) end(3) outcome(exposed)
file write tablecontent _n 


*Smoking status
tabulatevariable, variable(smokstatus) start(0) end(3)  outcome(exposed) 
file write tablecontent _n 

*Alc status
tabulatevariable, variable(alcohol_prob) start(1) end(1) outcome(exposed)
file write tablecontent _n 

*BMI
tabulatevariable, variable(bmi_cat) start(0) end(3) missing outcome(exposed)
file write tablecontent _n 

*Diabetes
tabulatevariable, variable(b_diab) start(1) end(1) outcome(exposed)

*CVD hypertension
foreach cond in b_cvd b_hyp b_ckd b_ra b_ibd b_coeliac b_lupus  b_depression {
tabulatevariable, variable(`cond') start(1) end(1) outcome(exposed)
}

file close tablecontent
}
log close