
*K_anfitinteractionmodels

cap log close
log using "$logfiles_an_dem/an_Primary_A2_cox-model-estimates_int", replace t

/*******************************************************************************
RUN INTERACTION MODELS FOR 9 MOST COMMON CANCERS AND ? MOST COMMON MH OUTCOMES
*******************************************************************************/

foreach db of  global databases {
foreach year in 0  1 {
foreach cancersite of global cancersites {
foreach outcome in dementia {
foreach intvar of any age_cat  {
*foreach intvar of any age_cat timesincediag3 gender gender ethnicity_binary calendaryearcat3 mostdeprived {

	use "$datafiles/cr_dataforDEManalysis_`db'_`cancersite'.dta", clear 
	keep if cancer=="`cancersite'"
	local year 1
	*Apply outcome specific exclusions
	drop if h_odementia==1
	
	dib "`cancersite' `outcome' `db' *`intvar'", stars

	*create new age category variable
	*Adults aged 25-49 contribute around a tenth (9%) of all new cancer cases 
	*Adults aged 50-74 account for 54% of all new cancer cases
	*people aged 75+ account for more than a third (36%)
	egen age_cat2=cut(age), at(15, 50, 65, 80, 140)
	tab age_cat2
	drop age_cat
	rename age_cat2 age_cat
	recode age_cat 15=1 50=2 65=3 80=4
	
	*include "$dofiles\analyse\inc_setupadditionalcovariates.do"
	include "$dofiles\analyse_mental_health\dementia/inc_excludepriorandset_dementia.do"
		
	*generate variables for use in interaction models
	local exposureinteractionspec "i.exposed i.exposed##i.`intvar'"

	if "`intvar'"=="calendaryearcat3" {	
		gen calendaryearcat3 = cal_year_gp
		local exposureinteractionspec "i.exposed 1.exposed##1.`intvar' 1.exposed##2.`intvar' 1.exposed##3.`intvar' 1.exposed##4.`intvar' 1.exposed##5.`intvar'"
		}
	if "`intvar'"=="mostdeprived" {	
		gen mostdeprived = (imd5==4|imd5==5)
		local exposureinteractionspec "i.exposed 1.exposed##1.`intvar'"
		}		
	if "`intvar'"=="timesincediag3" {
		stsplit timesincediag3, at(0,1,2,5,100,100) /*0:0-1, 1:1-2, 2:2-5, 5:5+ */
		local exposureinteractionspec "i.exposed 1.exposed##1.`intvar' 1.exposed##0.`intvar' i.exposed 1.exposed##2.`intvar' 1.exposed##5.`intvar' "
		}
	
	if "`intvar'"=="age_cat" {
		local exposureinteractionspec "i.exposed 1.exposed##1.`intvar' 1.exposed##2.`intvar' 1.exposed##3.`intvar' 1.exposed##4.`intvar'  "
	}
	if "`intvar'"=="ethnicity_binary" {	
		gen ethnicity_binary = eth5>=1
		local exposureinteractionspec "i.exposed 1.exposed##1.`intvar'"
		}	
		
	if "`intvar'"=="cprd_db" {	
		local exposureinteractionspec "i.exposed 1.exposed##1.`intvar'"
		}			

	if "`intvar'"=="living_alone" {	
		local exposureinteractionspec "i.exposed 1.exposed##1.`intvar'"
		}	
	*Only run models if there are >=10 failures in both groups IN EACH STRATUM
	tab exposed `intvar'
	local abort = 0
	levelsof `intvar', l(levels)
	foreach level of local levels{
	cou if exposed == 1 & `intvar'==`level' & _d==1
	*if r(N)<10 local abort = 1
	cou if exposed == 0 & `intvar'==`level' & _d==1
	*if r(N)<10 local abort = 1
	}
	if `abort'==0 {
	stcox  $covariates_common  `exposureinteractionspec', strata(set) iterate(1000)
	if _rc==0 estimates save "$results/dementia/an_Primary_A2_cox-model-estimates_int`intvar'_`cancersite'_`outcome'_`db'_dementia_`year'", replace
	
	/*if "`intvar'"=="gender" {
	/*rerun adjusted model because covariate classification has changed*/
	cap stcox exposed $covariates_common, strata(set) iterate(1000)
	if _rc==0 estimates save "$results/dementia/an_Primary_A2_cox-model-estimates_intadjusted_`cancersite'_`outcome'_`db'_dementia", replace
	}*/

} /*if at least 10 ev per group*/
} /* intvars */
} /* outcomes */
} /* sites */
} /*db*/
} /*year*/
log close
