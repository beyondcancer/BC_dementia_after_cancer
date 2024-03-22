*Look at records of liver cancer survivors with dementia diagnosis
preserve
use "$datafiles_an_dem/cr_dataforDEManalysis_aandg_liv.dta", clear



drop if main0_datedementia <= indexdate
rename indexdate doentry
		

gen doexit = min(doendcprdfup, main0_datedementia, d(29mar2021))

format doexit %dD/N/CY
drop if doentry == doexit /*NEW 21/09/18*/

*Censor controls at date of censor in cases
gen censordatecancer_temp=doexit if exposed==1
bysort setid: egen censordatecancer=max(censordatecancer_temp)
replace doexit = censordatecancer if doexit>censordatecancer

*Censor cases at date of all cases censored
gsort setid -exposed -doexit
gen censordatecontrol_temp=doexit if exposed==0
bysort setid: egen censordatecontrol=max(censordatecontrol_temp)
gen flag=1 if doexit>censordatecontrol
*list setid exposed doexit censordatecontrol  if flag==1 
replace doexit = censordatecontrol if doexit>censordatecontrol
format censordatecontrol %td

gen dementia= 1 if main0_datedementia<= doexit
recode dementia .=0
keep e_patid e_pracid exposed *dementia* doexit doentry cprd_db

tab dementia exposed, col

keep if dementia==1 & exposed==1 & cprd_db==1
*189 in Aurum
save  "$datafiles\liver_cancer_dementia_aurum.dta", replace
restore

/*
use  "$datafiles\cr_all_mh_Rx_outcomeevents_aurum.dta", clear
keep if binaryrxvar=="drugsdementia"
destring e_patid, replace
merge m:1 e_patid using "$datafiles\liver_cancer_dementia_aurum.dta", keep(match)
bysort e_patid (obsdate): keep if _n==1
keep e_patid obsdate 
gen drugs=1
save  "$datafiles\dementia_drugs_aurum.dta", replace /*7*/
*/
use "$datafiles\cr_all_mh_dx_outcomeevents_aurum.dta", clear
keep if binaryvar=="dementia"
destring e_patid, replace
merge m:1 e_patid using "$datafiles\liver_cancer_dementia_aurum.dta", keep(match)
bysort e_patid (obsdate): keep if _n==1
drop _m
merge m:1 lshtmcode using "$datafiles//aurummedicaldict_lookup.dta", keep(match master)

stop 
keep e_patid obsdate 
gen pricare=1
save  "$datafiles\dementia_pricare_aurum.dta", replace /*65*/

use "$datafiles\cr_all_mh_outcomeevents_HES_aurum.dta", clear
keep if binaryvar=="dementia"
destring e_patid, replace
merge m:1 e_patid using "$datafiles\liver_cancer_dementia_aurum.dta", keep(match) /*167*/
bysort e_patid (obsdate): keep if _n==1
keep e_patid obsdate icd
tab icd
gen hes=1
save  "$datafiles\dementia_hes_aurum.dta", replace
/*G31. 2 Degeneration of nervous system due to alcohol.
G31.9 Degenerative disease of nervous system, unspecified
*/

merge m:1 e_patid using "$datafiles\liver_cancer_dementia_aurum.dta", keep(match using)
drop _m
merge m:1 lshtmcode using "$datafiles//aurummedicaldict_lookup.dta", keep(match master)
merge 1:m e_patid using "$datafiles\dementia_drugs_aurum.dta"


foreach var in 
