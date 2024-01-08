
cap log close
log using "$logfiles_an_dem/cr_dataforDEManalysis_AandG", replace
********************************************************************************

use "$datafiles_an_dem/cr_dataforDEManalysis_aurum.dta", replace
append using  "$datafiles_an_dem/cr_dataforDEManalysis_gold.dta"

recode eth5_cprd 5=.
save  "$datafiles_an_dem/cr_dataforDEManalysis_AandG.dta", replace
cap log close

********************************************************************************

foreach site of global cancersites {
use	"$datafiles_an_dem/cr_dataforDEManalysis_AandG.dta", clear
keep if cancer=="`site'"
save "$datafiles_an_dem/cr_dataforDEManalysis_AandG_`site'.dta", replace
}


