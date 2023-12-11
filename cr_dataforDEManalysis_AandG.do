
cap log close
log using "$logfiles_an_dem/cr_dataforDEManalysis_AandG", replace
********************************************************************************

use "$datafiles/cr_dataforDEManalysis_aurum.dta", replace
gen cprd_db=1
append using  "$datafiles/cr_dataforDEManalysis_gold.dta"
replace cprd_db=0 if cprd_db==.

recode eth5 5=.
save  "$datafiles/cr_dataforDEManalysis_AandG.dta", replace
cap log close

********************************************************************************

foreach site of global cancersites {
use	"$datafiles/cr_dataforDEManalysis_AandG.dta", clear
keep if cancer=="`site'"
save "$datafiles/cr_dataforDEManalysis_AandG_`site'.dta", replace
}


