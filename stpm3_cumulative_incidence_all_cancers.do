/*
ssc install stpm3
ssc install standsurv
*/
cap file close tablecontent
file open tablecontent using "$results_an_dem\Table_CIF_dementia.txt", write text replace

file write tablecontent "Cancer" _tab "Time" _tab "Dementia CIF (95%CI), cancer survivors" _tab "Dementia CIF (95%CI), non-cancer participants" _n

cap log close
log using "$logfiles_an_dem/stpm3_cumulative_incidence_all_cancers.do", replace t

capture program drop stpm3cumpredincidences
program stpm3cumpredincidences
args outcome graphname
	
foreach cancersite of global cancersites {

use "$datafiles_an_dem/cr_dataforDEManalysis_aandg_`cancersite'.dta", clear 

*stset the data
	local year 0
	local outcome dementia	

	*Add 0.5 day to dementia DX if happen on same day as indexdate 
replace main0_datedementia=main0_datedementia+0.5 if main0_datedementia==indexdate

*Note: doendcprdfup=min(lcd,tod,deathdate,dod,enddate), where enddate includes date of cancer diagnosis in controls
drop if main0_datedementia<indexdate+(365.25*`year')
rename indexdate doentry
replace doentry=doentry +(365.25*`year')	
gen doexit = min(doendcprdfup, main0_datedementia, d(29mar2021))

*Add 0.5 day to end date if happen on same day as indexdate 
replace doexit=doexit+0.5 if doexit==doentry

format doexit %dD/N/CY
drop if doentry > doexit & exposed==0 
drop if doentry > doexit & exposed==1 

/*Censor controls at date of censor in cases
gen censordatecancer_temp=doexit if exposed==1
bysort setid: egen censordatecancer=max(censordatecancer_temp)
replace doexit = censordatecancer if doexit>censordatecancer

*Censor cases at date of all cases censored
gsort setid -exposed -doexit
gen censordatecontrol_temp=doexit if exposed==0
bysort setid: egen censordatecontrol=max(censordatecontrol_temp)
gen flag=1 if doexit>censordatecontrol

*list setid exposed doexit censordatecontrol  if flag==1 
replace doexit = censordatecontrol if doexit>=censordatecontrol
format censordatecontrol %td
*/

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


if "`outcome'"=="dementia" {
gen event= 1 if main0_datedementia<= doexit
replace event= 2 if (doexit==deathdate | doexit==deathdate) & deathdate!=. & doexit!=.
recode event .=0
}

	
*create unique id value to account for patients who are both in the control and control groups
sort e_patid exposed
gen id = _n
local covariatescleaned = subinstr(subinstr("$covariates_common", "i.smokstatus","",1), "i.", "", 2)

gen female = gender==2


if "`cancersite'"=="ora" | "`cancersite'"=="oes" | "`cancersite'"=="gas" |  "`cancersite'"=="col" |  "`cancersite'"=="liv" | "`cancersite'"=="pan" | "`cancersite'"=="lun" | "`cancersite'"=="mel" |   "`cancersite'"=="kid" | "`cancersite'"=="bla" | "`cancersite'"=="thy" | "`cancersite'"=="nhl" | "`cancersite'"=="mye" | "`cancersite'"=="leu" {
	xi i.smokstatus i.imd5 i.age_cat i.gender i.index_year_gr

stset doexit, id(id) failure(event = 1) enter(doentry) origin(doentry) exit(doexit) scale(365.25)
stpm3 exposed female _Iage_cat* _Iindex_yea*  _Iimd5*, scale(lncumhazard) df(4) 
estimates store dementia

stset doexit, id(id) failure(event = 2) enter(doentry) origin(doentry) exit(doexit) scale(365.25)
stpm3 exposed female _Iage_cat* _Iindex_yea*  _Iimd5*, scale(lncumhazard) df(4) 
estimates store death

}

*Single-sex "`cancersite'"s (don't include gender in model) 
if "`cancersite'"=="bre"	 | "`cancersite'"=="cer" | "`cancersite'"=="ute" | "`cancersite'"=="ova" | "`cancersite'"=="pro" {

	xi i.smokstatus i.imd5 i.age_cat i.gender i.index_year_gr

stset doexit, id(id) failure(event = 1) enter(doentry) origin(doentry) exit(doexit) scale(365.25)
stpm3 exposed _Iage_cat* _Iindex_yea*  _Iimd5*, scale(lncumhazard) df(4) 
estimates store dementia

stset doexit, id(id) failure(event = 2) enter(doentry) origin(doentry) exit(doexit) scale(365.25)
stpm3 exposed _Iage_cat* _Iindex_yea*  _Iimd5*, scale(lncumhazard) df(4) 
estimates store death
}

*CNS
if "`cancersite'"=="cns"  {
	xi i.smokstatus i.imd5 i.age_cat i.gender i.index_year_gr
	recode age_cat 1=2
stset doexit, id(id) failure(event = 1) enter(doentry) origin(doentry) exit(doexit) scale(365.25)
stpm3 exposed female  _Iindex_yea*  _Iimd5*, scale(lncumhazard) df(4) 
estimates store dementia

stset doexit, id(id) failure(event = 2) enter(doentry) origin(doentry) exit(doexit) scale(365.25)
stpm3 exposed female _Iindex_yea*  _Iimd5*, scale(lncumhazard) df(4) 
estimates store death

}
 
if e(converged)==1{

	*create the times to predict the cause-specific CIF 
		range tt 0 10 11

	* calculates the standardised failure function
standsurv, crmodels(dementia death) cif ci timevar(tt) frame(cif2, replace) ///
  at1(exposed 1) at2(exposed 0) atvar(F_exposed F_unexposed)                     ///
 contrast(difference) contrastvar(cif_diff)

frame cif2 {
  twoway (rarea F_exposed_dementia_lci F_exposed_dementia_uci tt, color(red%30))        ///
          (line F_exposed_dementia tt, color(red))                               ///
          (rarea F_unexposed_dementia_lci F_unexposed_dementia_uci tt, color(blue%30))   ///
          (line F_unexposed_dementia tt, color(blue))                            ///
          , legend(off) ///
          ylabel(, angle(h) format(%3.2f))  								 /// 
		  yscale(range(0 0.4)) 												///
          xtitle("Time from diagnosis (years)", size(tiny))                          ///
          ytitle("cause-specific CIF", size(tiny))                                   ///
          title("Dementia", size(small))                                                   ///
          name(dementia, replace)
                
   twoway (rarea F_exposed_death_lci F_exposed_death_uci tt, color(red%30))      ///
          (line F_exposed_death tt, color(red))                               ///
          (rarea F_unexposed_death_lci F_unexposed_death_uci tt, color(blue%30)) ///
          (line F_unexposed_death tt, color(blue))                            ///
          , legend(off)    ///
          ylabel(, angle(h) format(%3.2f))                                 ///
          yscale(range(0 0.4)) 												///
			xtitle("Time from diagnosis (years)", size(tiny))                            ///
            ytitle("cause-specific CIF", size(tiny))                                   ///
          title("Death" , size(small))                                                   ///
          name(death, replace)
		  
foreach time in 0 1 2 3 4 5 6 7 8 9 10 {
	sum  F_exposed_dementia if tt==`time'
	local F_exposed_dementia=`r(sum)' 
sum F_exposed_dementia_lci if tt==`time'
	local F_exposed_dementia_lci=`r(sum)' 
sum  F_exposed_dementia_uci if tt==`time'
	local F_exposed_dementia_uci=`r(sum)' 

sum  F_unexposed_dementia if tt==`time'
	local F_unexposed_dementia=`r(sum)' 
sum  F_unexposed_dementia_lci if tt==`time'
	local F_unexposed_dementia_lci=`r(sum)' 
sum  F_unexposed_dementia_uci if tt==`time'
		local F_unexposed_dementia_uci=`r(sum)' 
file write tablecontent "`cancersite'" _tab "`time'" _tab %4.3f (`F_exposed_dementia') " (" %4.3f (`F_exposed_dementia_lci') "-" %4.3f (`F_exposed_dementia_uci') ")" 
file write tablecontent _tab %4.3f (`F_unexposed_dementia') " (" %4.3f (`F_unexposed_dementia_lci') "-" %4.3f (`F_unexposed_dementia_uci') ")"  _n
}	  
		  
}               
 
 
 *, legend(order(2 "Exposed" 4 "Unexposed") cols(1) ring(0) pos(11))
  if "`cancersite'"=="ora"	local cancersite2="Oral cavity (C00-06)"    
 if "`cancersite'"=="oes"	local cancersite2="Oesophageal (C15)"	 	  
 if "`cancersite'"=="gas"	local cancersite2="Stomach (C16)" 		  
  if "`cancersite'"=="col"	local cancersite2="Colorectal (C18-20)"    
 if "`cancersite'"=="liv"	local cancersite2="Liver (C22)"		  	  
  if "`cancersite'"=="pan"	local cancersite2="Pancreas (C25)"		   
  if "`cancersite'"=="lun"	local cancersite2="Lung (C34)"  		  	  
  if "`cancersite'"=="mel"	local cancersite2="Malignant melanoma (C43)" 
  if "`cancersite'"=="bre"	local cancersite2="Breast (C50)" 		 
  if "`cancersite'"=="cer"	local cancersite2="Cervix (C53)" 		
  if "`cancersite'"=="ute"	local cancersite2="Uterus (C54-55)" 	  	  
  if "`cancersite'"=="ova"	local cancersite2="Ovary (C56)" 		  	 
  if "`cancersite'"=="pro"	local cancersite2="Prostate (C61)"		 
  if "`cancersite'"=="kid"	local cancersite2="Kidney (C64)" 		  	  
  if "`cancersite'"=="bla"	local cancersite2="Bladder (C67)" 		
  if "`cancersite'"=="cns"	local cancersite2="CNS (C71-72)" 		  	  
  if "`cancersite'"=="thy"	local cancersite2="Thyroid (C73)" 		 
  if "`cancersite'"=="nhl"	local cancersite2="NHL (C82-85)" 		  	
  if "`cancersite'"=="mye"	local cancersite2="Multiple myeloma (C90)"   
  if "`cancersite'"=="leu"	local cancersite2="Leukaemia (C91-95)"   	
 
 graph combine dementia death, nocopies ycommon title("`cancersite2'", size(small))            
 graph save "Graph" "$results_an_dem\stpm3cumrisk_`outcome'`cancersite'.gph", replace
graph export "$results_an_dem\stpm3cumrisk_`outcome'`cancersite'.pdf", as(pdf) name("Graph") replace
		
	* EXPORT ESTIMATES FOR TABLE WITH CUMULATIVE INCIDENCE AT 5 AND 10 YEARS
	*keep cancer tt _est*
	
	}
}
end


stpm3cumpredincidences dementia



 graph combine "$results_an_dem\stpm3cumrisk_dementiaora.gph" "$results_an_dem\stpm3cumrisk_dementiaoes.gph" "$results_an_dem\stpm3cumrisk_dementiagas.gph" ///
 "$results_an_dem\stpm3cumrisk_dementiacol.gph" "$results_an_dem\stpm3cumrisk_dementialiv.gph" "$results_an_dem\stpm3cumrisk_dementiapan.gph" ///
 "$results_an_dem\stpm3cumrisk_dementialun.gph" "$results_an_dem\stpm3cumrisk_dementiamel.gph" "$results_an_dem\stpm3cumrisk_dementiabre.gph" ///
 "$results_an_dem\stpm3cumrisk_dementiacer.gph" "$results_an_dem\stpm3cumrisk_dementiaute.gph" "$results_an_dem\stpm3cumrisk_dementiaova.gph" ///
 "$results_an_dem\stpm3cumrisk_dementiapro.gph" "$results_an_dem\stpm3cumrisk_dementiakid.gph" "$results_an_dem\stpm3cumrisk_dementiabla.gph" ///
 "$results_an_dem\stpm3cumrisk_dementiacns.gph" "$results_an_dem\stpm3cumrisk_dementiathy.gph" "$results_an_dem\stpm3cumrisk_dementianhl.gph" ///
 "$results_an_dem\stpm3cumrisk_dementiamye.gph" "$results_an_dem\stpm3cumrisk_dementialeu.gph", nocopies ycommon ro(5) imargin(1 1 1 1)          
graph export "$results_an_dem\stpm3cumrisk_final.emf", as(emf) name("Graph") replace
		