
cap log close
log using "$logfiles_an_dem/cr_dataforDEManalysis_AandG", replace
********************************************************************************

use "$datafiles_an_dem/cr_dataforDEManalysis_aurum.dta", replace
append using  "$datafiles_an_dem/cr_dataforDEManalysis_gold.dta"
tab exposed
recode eth5_cprd 5=.
recode smokstatus 12=2
	gen eth5_comb=eth5_cprd
	replace eth5_comb=eth5_hes if eth5_comb==.
	 	recode b_cvd .=0
	recode eth5_comb 4=3

save  "$datafiles_an_dem/cr_dataforDEManalysis_AandG.dta", replace
cap log close

********************************************************************************

foreach site of global cancersites {
use	"$datafiles_an_dem/cr_dataforDEManalysis_AandG.dta", clear
keep if cancer=="`site'"

*Check all cases have at least one control
gsort setid exposed
drop anyunexposed
bysort setid: egen anyunexposed=min(exposed)
drop if anyunexposed==1

*Drop controls without a case
gsort setid -exposed
drop anyexposed
bysort setid: egen anyexposed=max(exposed)
drop if anyexposed==0

*Drop sets without an exposed person
bysort setid: egen maxexposed=max(exposed)
tab maxex
drop if max==0
save "$datafiles_an_dem/cr_dataforDEManalysis_AandG_`site'.dta", replace
}


