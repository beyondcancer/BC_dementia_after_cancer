*Author: Harriet Forbes
*Date: 28th July 2026
*Aim: to compare the age, sex and calendar period of cancer survivors in the final cohort, with those dropped due to have no eligible controls

****Aurum

*All eligible cancer survivors
use "Z:\GPRD_GOLD\Krishnan\20_000268\20_000268_1st_Delivery (cohort derivation)\cohortdefinition\datafiles/cr_exposed_cohort_aurum.dta", clear
keep if exposed==1


*Merge with cancer survivors with eligible matches
merge 1:m e_patid exposed  using "$datafiles//matchedcohort_allcancers_aurum_10.dta", keep(match master)

replace indexdate=eventdate if indexdate==.

* Generate date of birth as 1 July of the year in yob
gen dob = mdy(7, 1, yob)

* Format as a readable Stata daily date
format dob %td

* Generate age at indexdate
gen age = (indexdate - dob)/365.25

*Generate calendar year of diagnosis 
gen cal_yr_diagnosis = year(indexdate)
egen cal_yr_diagnosis_gp = cut(cal_yr_diagnosis), at(1999 2006 2011 2016 2020)


*Compare
bysort _m: tab gender
bysort _m: sum age
bysort _m: tab cal_yr_diagnosis_gp


save "$datafiles_an_dem/an_20_compare_cases_excluded_no_matches_aurum.dta", replace

****Gold

*All eligible cancer survivors
use "Z:\GPRD_GOLD\Krishnan\20_000268\20_000268_1st_Delivery (cohort derivation)\cohortdefinition\datafiles/cr_exposed_cohort_gold.dta", clear
keep if exposed==1


*Merge with cancer survivors with eligible matches
merge 1:m e_patid exposed  using "$datafiles//matchedcohort_allcancers_gold_10.dta", keep(match master)

replace indexdate=eventdate if indexdate==.

*Recode gender to alig with Aurum data
gen gender2="F" if gender==2 
replace gender2="M" if gender==1 
drop gender 
rename gender2 gender

* Generate date of birth as 1 July of the year in yob
gen dob = mdy(7, 1, yob)

* Format as a readable Stata daily date
format dob %td

* Generate age at indexdate
gen age = (indexdate - dob)/365.25

*Generate calendar year of diagnosis 
gen cal_yr_diagnosis = year(indexdate)
egen cal_yr_diagnosis_gp = cut(cal_yr_diagnosis), at(1999 2006 2011 2016 2020)


*Compare
bysort _m: tab gender
bysort _m: sum age
bysort _m: tab cal_yr_diagnosis_gp


append using "$datafiles_an_dem/an_20_compare_cases_excluded_no_matches_aurum.dta"


egen age_cat = cut(age), at(18 50 60 70 80 150) label

label define age_cat_lbl ///
    0 "18–49" ///
    1 "50–59" ///
    2 "60–69" ///
    3 "70–79" ///
    4 "≥80", replace

label values age_cat age_cat_lbl

tab age_cat, missing

replace cancer=cancercat if cancer==""

*Compare
bysort _m: tab gender
bysort _m: tab cal_yr_diagnosis_gp
bysort _m: sum age, d
bysort _m: tab age_cat

tab cancer if _m==3
tab cancer if _m==1





