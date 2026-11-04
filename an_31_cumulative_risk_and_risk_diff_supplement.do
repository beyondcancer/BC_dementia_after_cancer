*Author: Harriet
*Date: 29th October 2026
*Aim: put cumulatve risks from total effect into a table, along with the risk difference

use "$results_an_dem/hpc_output/results/an_cdekm_EstimatesAndBSCIs", clear
keep if estimand=="Total"
keep  if statis=="RD"
keep cancertype horizon risk_exposed risk_unexposed rr lci uci 
order cancertype horizon risk_exposed risk_unexposed rr lci uci 
foreach x in risk_exposed risk_unexposed rr lci uci {
	gen `x'_percent=`x'*100
}

gen RD_95CI = string(rr_p, "%9.2f") + " (" + string(lci_p, "%9.2f") + "-" + string(uci_p, "%9.2f") + ")" 

keep cancertype horizon risk_exposed_percent risk_unexposed_percent RD_95CI
list in 1/10
*Table Risk exposed | risk unexposed | RD (95% CI)
*Mulitply by 100 for %

gen cancer_order = .
local i = 0

foreach site of global cancersites {
    local i = `i' + 1
    replace cancer_order = `i' if cancertype == "`site'"
}


keep cancer* horizon risk_exposed_percent risk_unexposed_percent RD_95CI
sort cancer_order horizon risk_exposed_percent risk_unexposed_percent RD_95CI
list in 1/5
