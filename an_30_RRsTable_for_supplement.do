*Table of Figure 5 (different estimands) for supplement

use "$results_an_dem/hpc_output/results/an_cdekm_EstimatesAndBSCIs", clear

drop if statis=="RD"

keep cancer estimand stat horizon rr lci uci

gen str20 rr_string = string(rr, "%4.2f")
gen str20 lci_string = string(lci, "%4.2f")
gen str20 uci_string = string(uci, "%4.2f")
gen rr_lci_uci=rr_string + " (" + lci_string + "-" + uci_string + ")"


gen cancer_order = .
local i = 0

foreach site of global cancersites {
    local i = `i' + 1
    replace cancer_order = `i' if cancertype == "`site'"
}


keep cancer* estimand stat horizon rr_lci_uci
sort cancer_order estimand stat horizon
list in 1/5


* Reshape so CDE and Total RRs are side by side
reshape wide rr_lci_uci, i(cancertype horizon) j(estimand) string
sort cancer_order stat horizon

*Absolute incidence 
use "$results_an_dem/hpc_output/results/an_cdekm_curve", clear
keep if cancer=="bla"
keep if estimand=="Total"

*Truncate at 10 years
line  cuminc time_years if exposed==0 || line cuminc time_years if exposed==1 

**# Bookmark #1


