	use "$datafiles/cr_dataforDEManalysis_gold.dta", clear 
	*keep if cancer=="lun"
	tab exposed /*101,127 with cancer*/
		sum age if exposed==1 /*69 years*/
	drop if h_odementia==1
	count

	local outcome dementia 
local year 0
	include "$dofiles\analyse_mental_health\dementia/inc_excludepriorandset_dementia.do" /*excludes prior specific outcomes and st sets data*/
	
	stcox exposed if cancer=="bre", strata(set) iterate(1000)
	stcox exposed if cancer=="lun", strata(set) iterate(1000)
	stcox exposed if cancer=="col", strata(set) iterate(1000)
	
	/*louise criteria*/
	/*	start of follow-up was defined as the earliest date of cancer diagnosis
End date (earliest of:  transfer out date, the practice's last collection date, date of death (ONS data), study-end (2016), a dementia diagnosis, or a second cancer diagnosis, whichever occurred first. Cancer patients could act as potential controls until their first cancer diagnosis.*/
	*Gold
	*keep if cprd_db==0
	tab exposed
	
	*Diagosed prior to 2017
	drop if doentry>d(31dec2016)
	tab exposed /*96k  with cancer*/
	
	stcox exposed if cancer=="bre", strata(set) iterate(1000)
	stcox exposed if cancer=="lun", strata(set) iterate(1000)
	stcox exposed if cancer=="col", strata(set) iterate(1000)
	
	
	
	*12 months follow-up after indexdate
	gen fup=(doendcprdfup-doentry)/365.25
	sum fup
	drop if fup<1	
	tab exposed /*60k  with cancer*/
	
	stcox exposed if cancer=="bre", strata(set) iterate(1000)
	stcox exposed if cancer=="lun", strata(set) iterate(1000)
	stcox exposed if cancer=="col", strata(set) iterate(1000)
	
	
	* patients alive and still registered to UTS practices within CPRD GOLD at age 65
	gen date_65=dob+(365.25*65)
	format date_65 %td
	list doentry  doend dob date_65  in 1/25
	
	gen age65criteria=1 if dostart<=date_65 & doendcprdfup>date_65
	keep if age65criteria==1
	tab exposed /*27k  with cancer*/
	
	sum age if exposed==1 /*68 years*/
	sum age if exposed==0
	
	stcox exposed if cancer=="bre", strata(set) iterate(1000)
	stcox exposed if cancer=="lun", strata(set) iterate(1000)
	stcox exposed if cancer=="col", strata(set) iterate(1000)
	
	*exclude those with Cancer diagnosis and dementia within one year of each other
	gen time_to_dx=(main0_datedementia-doentry)/365.25
	sum time_to_dx if exposed==1, d
	drop if time_to_dx<=1 & exposed==1
	tab exposed /*25k  with cancer*/
	
	stcox exposed if cancer=="bre", strata(set) iterate(1000)
	stcox exposed if cancer=="lun", strata(set) iterate(1000)
	stcox exposed if cancer=="col", strata(set) iterate(1000)
	
	stptime if exposed==1 & cancer=="bre", per(1000)
	stptime if exposed==0 & cancer=="bre", per(1000) 
stop	
	drop if time_to_dx<=1 
	tab exposed /*27k  with cancer*/
	
	stcox exposed if cancer=="bre", strata(set) iterate(1000)
	stcox exposed if cancer=="lun", strata(set) iterate(1000)
	stcox exposed if cancer=="col", strata(set) iterate(1000)
	

	
	sum age if exposed==1 /*68 years: note mean age is 73 in Louisa's dataset*/
	sum age if exposed==0
	tab exposed
	
	
	stptime if exposed==1 & cancer=="bre", per(1000)
	stptime if exposed==0 & cancer=="bre", per(1000) 

	stcox exposed, strata(set) iterate(1000)
	stcox exposed if cancer=="bre", strata(set) iterate(1000)
	stcox exposed if cancer=="lun", strata(set) iterate(1000)
	*stcox exposed b_nocons, strata(set) iterate(1000)

	stop 

	
	


	sum age
	cap drop age_3years
	gen age_3years=age+3
	gen indexdate_3years=doentry+(365.25*3)
	format indexdate_3years %td
	sum age_3years if exposed==1
	sum age_3years if exposed==0
	sum age_3years if exposed==1 & indexdate_3years<doexit
	sum age_3years if exposed==0 & indexdate_3years<doexit	
	
list e_patid exposed lcd diagnosisdatebest2 doendcprdfup main0_datedementia doentry doexit _* if setid==409105010236	

tab b_gp exposed, nolab
	stcox exposed if b_gpnocons>=10, strata(set) iterate(1000)
	stcox exposed if b_gpnocons>=4, strata(set) iterate(1000)
	stcox exposed if b_gpnocons>=1, strata(set) iterate(1000)

	*/
	egen age_5=cut(age), at(18 25 (5) 120)
	tab age_5
	cap postclose failures
postfile failures str5 cancersite age pop_unexp tot_obscases_unexp obscases_unexp rate_unexp pop_exp tot_obscases_exp obscases_exp rate_exp using "$results/dementia/an_dataset_for_sir_calc", replace

	foreach age in 18 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 {
	foreach exposed in 0 1 {
	count if exposed==`exposed' & dementia==1
	local tot_dementia_`exposed'=r(N)	
	stptime if exposed==1 & age_5==`age'
	local rate_`exposed' = r(rate)
	count if exposed==`exposed' & age_5==`age'
	local totaln_`exposed'=r(N)
	count if exposed==`exposed' & age_5==`age' & dementia==1
	local dementias_`exposed'=r(N)

	}
	post failures ("oes") (`age') (`totaln_0') (`tot_dementia_0') (`dementias_0') (`rate_0') (`totaln_1') (`tot_dementia_1') (`dementias_1') (`rate_1') 		
	}
	postclose failures
	
use "J:\EHR-Working\Krishnan\20_000268\results\mental_health\dementia\an_dataset_for_sir_calc.dta" , clear

stop 


*Calculate expected number of cases (multiplying each age-specific dementia incidence 
*rate of the reference population by each age-specific population of the 
*community in question and then adding up the results
 gen E_cases=rate_unexp*pop_exp
 egen tot_obs=total(obscases_exp)
egen tot_expected=total(E_cases)
list
di tot_obs/tot_exp

*SIR matches well! if use 5-year age groups

/*
list
preserve
keep if exposed=="0"
drop exposed
drop dementia 
list
save "J:\EHR-Working\Krishnan\20_000268\results\mental_health\dementia\an_UNEXPOSEDdataset_for_sir_calc.dta", replace
 restore
 
 keep if exposed=="1"
 drop dementias
 
 
merge 1:1 cancer age using  "J:\EHR-Working\Krishnan\20_000268\results\mental_health\dementia\an_UNEXPOSEDdataset_for_sir_calc.dta"


list

 
istdize dementia pop age using "J:\EHR-Working\Krishnan\20_000268\results\mental_health\dementia\an_UNEXPOSEDdataset_for_sir_calc.dta",  popvars(dementias pop) print	


// Load data
use mydata.dta

// Calculate expected number of cases
dstdize age sex, by(region) pop(uspop) gen(exp_cases)

// Calculate observed number of cases
gen obs_cases = cases / person_years * 100000

// Calculate total person-years at risk
stset time, failure(cases)

// Join expected and observed number of cases and total person-years at risk
stjoin exp_cases obs_cases _dstdize1 _dstdize2 _dstdize3 _dstdize4 _dstdize5

// Split data into strata
stsplit _dstdize1 _dstdize2 _dstdize3 _dstdize4 _dstdize5

// Calculate confidence intervals for each stratum
stci, by(_t)

// Calculate SIR
ststdize exp_cases obs_cases _t, by(region)
	
