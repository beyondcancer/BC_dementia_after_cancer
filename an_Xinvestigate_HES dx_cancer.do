log using "$logfiles_an_dem/an_HES_codes_dementia_by_cancer.txt", replace t


*Look at records of liver cancer survivors with dementia diagnosis
qui foreach cancersite of global cancersites {

noi di "`cancersite'"
use "$datafiles_an_dem/cr_dataforDEManalysis_aandg_`cancersite'.dta", clear

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

preserve
keep if dementia==1 & exposed==1 & cprd_db==1
*189 in Aurum
save  "$datafiles\exp_dementia_aurum_`cancersite'.dta", replace
restore
keep if dementia==1 & exposed==0 & cprd_db==1
*189 in Aurum
save  "$datafiles\unexp_dementia_aurum_`cancersite'.dta", replace



use "$datafiles\cr_all_mh_outcomeevents_HES_aurum.dta", clear
keep if binaryvar=="dementia"
destring e_patid, replace
merge m:1 e_patid using "$datafiles\exp_dementia_aurum_`cancersite'.dta", keep(match) nogen /*167*/
merge m:1 icd using "J:\EHR-Working\Krishnan\20_000268\codelists\cr_codelist_dementia_HES.dta", keep(match)
bysort e_patid (obsdate): keep if _n==1
keep e_patid obsdate icd desc
noi tab icd, sort freq
tab desc

	use "$datafiles\cr_all_mh_outcomeevents_HES_aurum.dta", clear
keep if binaryvar=="dementia"
destring e_patid, replace
merge m:1 e_patid using "$datafiles\unexp_dementia_aurum_`cancersite'.dta", keep(match) nogen /*167*/
merge m:1 icd using "J:\EHR-Working\Krishnan\20_000268\codelists\cr_codelist_dementia_HES.dta", keep(match)
bysort e_patid (obsdate): keep if _n==1
keep e_patid obsdate icd desc
noi tab icd, sort freq
tab desc
}
log close 
stop 

*Look at records of liver cancer survivors with dementia diagnosis
qui {
use "$datafiles_an_dem/cr_dataforDEManalysis_aandg.dta", clear

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

preserve
keep if dementia==1 & exposed==1 & cprd_db==1
*189 in Aurum
save  "$datafiles\exp_dementia_aurum.dta", replace
restore
keep if dementia==1 & exposed==0 & cprd_db==1
*189 in Aurum
save  "$datafiles\unexp_dementia_aurum.dta", replace



use "$datafiles\cr_all_mh_outcomeevents_HES_aurum.dta", clear
keep if binaryvar=="dementia"
destring e_patid, replace
merge m:1 e_patid using "$datafiles\exp_dementia_aurum.dta", keep(match) nogen /*167*/
merge m:1 icd using "J:\EHR-Working\Krishnan\20_000268\codelists\cr_codelist_dementia_HES.dta", keep(match)
bysort e_patid (obsdate): keep if _n==1
keep e_patid obsdate icd desc
noi tab icd, sort freq
tab desc

	use "$datafiles\cr_all_mh_outcomeevents_HES_aurum.dta", clear
keep if binaryvar=="dementia"
destring e_patid, replace
bysort e_patid (obsdate): keep if _n==1
merge 1:m e_patid using "$datafiles\unexp_dementia_aurum.dta", keep(match) nogen /*167*/
merge m:1 icd using "J:\EHR-Working\Krishnan\20_000268\codelists\cr_codelist_dementia_HES.dta", keep(match)
bysort e_patid (obsdate): keep if _n==1
keep e_patid obsdate icd desc
noi tab icd, sort freq
tab desc
}
*overall very similar distribution
	

	
