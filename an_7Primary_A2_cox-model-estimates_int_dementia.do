
*K_anfitinteractionmodels
*set trace on
set trace off
cap log close
log using "$logfiles_an_dem/an_Primary_A2_cox-model-estimates_int", replace t

/*******************************************************************************
RUN INTERACTION MODELS FOR 9 MOST COMMON CANCERS AND ? MOST COMMON MH OUTCOMES
*******************************************************************************/

foreach db of  global databases {
foreach year in 0 {
foreach cancersite of global cancersites {
foreach outcome in dementia {
	*
foreach intvar of any age_cat_dementia gender eth5_comb calendaryearcat3 mostdeprived region_cat {

	use "$datafiles_an_dem/cr_dataforDEManalysis_`db'_`cancersite'.dta", clear 
	keep if cancer=="`cancersite'"
	*Apply outcome specific exclusions
	drop if h_odementia==1
	
	noi di "`cancersite' `outcome' `db' *`intvar'"

	*create new age category variable
	*Adults aged 25-49 contribute around a tenth (9%) of all new cancer cases 
	*Adults aged 50-74 account for 54% of all new cancer cases
	*people aged 75+ account for more than a third (36%)
*Age (years)
egen age_cat_dementia=cut(age), at(17 50 60 70 80 200)
recode age_cat_dementia 17=1 50=2 60=3 70=4 80=5
lab define age_cat_dementia 1 "18-49" 2 "50-59" 3 "60-69" 4 "70-79" 5 "80+"
lab val age_cat_dementia age_cat_dementia
	
	egen cal_year_gp=cut(index_year), at(1998 2003 2009 2015 2020)
	recode cal_year_gp 1998=1 2003=2 2009=3 2015=4
	
	*include "$dofiles\analyse\inc_setupadditionalcovariates.do"
	include "$dofiles_an_dem/inc_excludepriorandset_dementia.do"
		
	*generate variables for use in interaction models
	local exposureinteractionspec "i.exposed i.exposed##i.`intvar'"

	if "`intvar'"=="calendaryearcat3" {	
		gen calendaryearcat3 = cal_year_gp
		local exposureinteractionspec "i.exposed 1.exposed##1.`intvar' 1.exposed##2.`intvar' 1.exposed##3.`intvar' 1.exposed##4.`intvar'"
		}
	if "`intvar'"=="mostdeprived" {	
		gen mostdeprived = (imd5==4|imd5==5)
		local exposureinteractionspec "i.exposed 1.exposed##1.`intvar'"
		}		
	
	if "`intvar'"=="age_cat_dementia" {
		local exposureinteractionspec "i.exposed 1.exposed##1.`intvar' 1.exposed##2.`intvar' 1.exposed##3.`intvar' 1.exposed##4.`intvar' 1.exposed##5.`intvar' "
	}
	if "`intvar'"=="eth5_comb" {	
		local exposureinteractionspec "i.exposed 1.exposed##0.`intvar' 1.exposed##1.`intvar' 1.exposed##2.`intvar' 1.exposed##3.`intvar'"		
		}	
		
	if "`intvar'"=="region_cat"  { /*1=north 2=east 3=west 4=south 5=london*/ 
		gen region_cat = region
		recode region_cat 2/3=1 4=2 6=2 5=3 7=5 8/9=4
		local exposureinteractionspec "i.exposed 1.exposed##1.`intvar' 1.exposed##2.`intvar' 1.exposed##3.`intvar' 1.exposed##4.`intvar' 	1.exposed##5.`intvar' "
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
	if _rc==0 estimates save "$results_an_dem/an_Primary_A2_cox-model-estimates_int`intvar'_`cancersite'_`outcome'_`db'_dementia_`year'", replace
	
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
