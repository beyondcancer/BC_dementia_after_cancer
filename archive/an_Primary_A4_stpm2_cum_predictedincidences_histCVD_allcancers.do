/*ssc install stpm2
ssc install rcsgen
ssc install stpm2_standsurv
ssc install moremata
ssc install standsurv
*/

cap log close
log using "$logfiles_an_dem/an_Primary_A4_stpmpredictedincidences_allcancers", replace t

capture program drop stpmcumpredincidences
program stpmcumpredincidences
args outcome graphname
	
foreach cancersite of global cancersites {

use "$datafiles_an_dem/cr_dataforDEManalysis_aandg_`cancersite'.dta", clear 
	local year 0
	local outcome dementia
	dib " `outcome' `db'", stars

	*gen tenyearsfup=indexdate+(10*365.25)
	*replace doendcprdfup=min(doendcprdfup, tenyearsfup)
	*include "$Dodir\analyse\inc_setupadditionalcovariates.do" /*defines female and site specific covariates*/
	include "$dofiles_an_dem/inc_excludepriorandset_dementia.do" /*excludes prior specific outcomes and st sets data*/
	 
	 
	*tab dementia exposed if b_cvd==0, miss col 
	*sts graph if b_cvd==0, by(exposed) cumhaz
	*sts graph if b_cvd==0, by(exposed) 
	
	*tab dementia exposed if b_cvd==1, miss col 
	sts graph if b_cvd==1, by(exposed) cumhaz
	*stop
/*generate bmi splines
mkspline bmispl=bmi, cubic nk(3) dis
summ bmispl1 if exposed==1
local bmispl1mean = r(mean)
summ bmispl2 if abs(bmispl1-`bmispl1mean')<0.01
local bmispl2ref = r(mean)
replace bmispl2=`bmispl2ref'
replace bmispl1=`bmispl1mean'
*/
	sts graph if b_cvd==0, by(exposed) cumhaz saving("$results_an_dem/stpm2cumrisk_`outcome'_`cancersite'", replace)	
local covariatescleaned = subinstr(subinstr("$covariates_common", "i.smokstatus","",1), "i.", "", 2)

gen female = gender==2

xi i.smokstatus i.imd5 i.age_cat i.gender i.index_year_gr
di "here 1"
*TVC exposed - exposure effect is allowed to be time-varying Ii.e. allow non-proportional hazards
*DFTVC - allows line wobble

if "`cancersite'"=="ora" | "`cancersite'"=="oes" | "`cancersite'"=="gas" |  "`cancersite'"=="col" |  "`cancersite'"=="liv" | "`cancersite'"=="pan" | "`cancersite'"=="lun" | "`cancersite'"=="mel" |   "`cancersite'"=="kid" | "`cancersite'"=="bla" | "`cancersite'"=="cns" | "`cancersite'"=="thy" | "`cancersite'"=="nhl" | "`cancersite'"=="mye" | "`cancersite'"=="leu" {
stpm2 exposed b_cvd female _Iage_cat* _Iindex_yea* alcohol_prob _Iimd5* _Ismok* b_diab b_hyp b_ckd b_depression, scale(hazard) df(4) tvc(exposed) dftvc(4) eform iterate(1000) base
}
*Single-sex "`cancersite'"s (don't include gender in model) 
if "`cancersite'"=="bre"	 | "`cancersite'"=="cer" | "`cancersite'"=="ute" | "`cancersite'"=="ova" | "`cancersite'"=="pro" {
stpm2 exposed b_cvd _Iage_cat* _Iindex_yea* alcohol_prob b_diab b_hyp b_ckd b_depression _Iimd5* _Ismok*, scale(hazard) df(4) tvc(exposed) dftvc(4) eform iterate(1000) base
}
di "here 2"
 
if e(converged)==1{

	range timevar 0 21 1000

	* Standardised variables distribution taking the exposed group as ref (through exposed==1) PC lambert blog on standardised survival curves
	* if exposed group had not had cancer, that gives the predicted incidence in unexposed: do a KM to check in cancer group - cancer group curves should look same from KM cumulatove incidence
	stpm2_standsurv if exposed==1, atvar(exp0b_cvd0 exp0b_cvd1 exp1b_cvd0 exp1b_cvd1) at1(exposed 0 b_cvd 0) at2(exposed 0 b_cvd 1) at3(exposed 1 b_cvd 0) at4(exposed 1 b_cvd 1) timevar(timevar) ci contrast(difference) fail


	* GRAPH
	gen date = timevar
	keep if timevar<=10

	*di cancertype
	*local title=cancertype
	if "`outcome'"=="dementia"  {
	twoway  (rarea exp0b_cvd0_lci exp0b_cvd0_uci date, color(blue%25))  ///
			(rarea exp0b_cvd1_lci exp0b_cvd1_uci date, color(red%25)) ///
			(rarea exp1b_cvd0_lci exp1b_cvd0_uci date, color(blue%25)) ///
			(rarea exp1b_cvd1_lci exp1b_cvd1_uci  date, color(red%25)) ///
			(line exp0b_cvd0 date, sort lpattern(dash) lcolor(blue)) ///
			(line exp1b_cvd0 date, sort lcolor(blue)) ///
			(line exp0b_cvd1 date, sort lpattern(dash) lcolor(red)) ///
			(line exp1b_cvd1 date, sort lcolor(red)) ///
			 , legend(order(1 "No hist. CVD" 2 "Hist. CVD" 5 "No cancer" 6 "Cancer" 7 "No cancer" 8 "Cancer") ring(0) cols(6) pos(11) size(tiny)) ///
			 ylabel(0(0.2)1.0,angle(h) format(%3.2f) labsize(tiny)) xlabel(0(1)10) ///
			 ytitle("Incidence (per 100 person years)", size(tiny)) title("`outcome'") ///
			 xtitle("Time since cancer diagnosis (years)") 
			 
	graph save "Graph" "$results_an_dem\stpm2cumrisk_`outcome'`cancersite'.gph", replace
	graph export "$results_an_dem\stpm2cumrisk_`outcome'`cancersite'.pdf", as(pdf) name("Graph") replace
	
	
	* EXPORT ESTIMATES FOR TABLE WITH CUMULATIVE INCIDENCE AT 5 AND 10 YEARS
	keep cancer date exp*
	
save "$results_an_dem/cumrisk_`outcome'_`cancersite'", replace
	}
}
}
end

foreach outcome in dementia   {
di "** `outcome' **"
stpmcumpredincidences `outcome' 
}

use "$results_an_dem/cumrisk_dementia_ora", clear
foreach cancersite of global cancersites {
append using "$results_an_dem/cumrisk_dementia_`cancersite'"
}
duplicates drop 

foreach x in exp0b_cvd0 exp0b_cvd0_lci exp0b_cvd0_uci exp0b_cvd1 exp0b_cvd1_lci exp0b_cvd1_uci exp1b_cvd0 exp1b_cvd0_lci exp1b_cvd0_uci exp1b_cvd1 exp1b_cvd1_lci exp1b_cvd1_uci {
replace `x'=`x'*100	
}
save "$results_an_dem/an_stpm2_cum_predictedincidences_allcancers_cis", replace
desc

