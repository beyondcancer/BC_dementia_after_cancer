*run results where follow-up starts at birth...

	use "$datafiles_an_dem/cr_dataforDEManalysis_gold.dta", clear 
		local year 1
	*Apply outcome specific exclusions
	drop if h_odementia==1
	drop if h_o365_`year'dementia==1

*drop individuals with outcome event prior to index date and create stset variables
*results may not be generalisable to risk of recurrent specific CVD events

drop if main`year'_datedementia <= indexdate+(365.25*`year')
rename indexdate doentry
replace doentry=doentry +(365.25*`year')		

*Note: doendcprdfup=min(lcd,tod,deathdate,dod, enddate), where enddate includes date of 
*cancer diagnosis in controls
gen doexit = min(doendcprdfup, main`year'_datedementia, d(29mar2021))
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
list setid exposed doexit censordatecontrol  if flag==1 
replace doexit = censordatecontrol if doexit>censordatecontrol
format censordatecontrol %td

cap drop dementia

gen dementia= 1 if main`year'_datedementia<= doexit

gen month=7
gen day=1
gen dob=mdy(month, day, yob)
*create unique id value to account for patients who are both in the control and control groups
sort e_patid exposed
gen id = _n
stset doexit, id(id) failure(dementia = 1) enter(dob) origin(dob) exit(doexit) scale(365.25)


	stcox exposed
	stcox exposed i.age_cat
	stcox exposed, strata(set) vce(robust) iterate(1000)
	 stcox exposed $covariates_common i.b_cvd i.b_hyp, strata(set) iterate(1000)
	 
stset doexit, id(id) failure(dementia = 1) enter(doentry) origin(doentry) exit(doexit) scale(365.25)
	 stcox exposed $covariates_common i.b_cvd i.b_hyp, strata(set) iterate(1000)

	 	/*louise criteria*/
	/*	start of follow-up was defined as the earliest date of cancer diagnosis
End date (earliest of:  transfer out date, the practice's last collection date, date of death (ONS data), study-end (2016), a dementia diagnosis, or a second cancer diagnosis, whichever occurred first. Cancer patients could act as potential controls until their first cancer diagnosis.*/
	*Gold
	keep if cprd_db==0
	tab exposed
		stcox exposed, strata(set) iterate(1000)

	*Diagosed prior to 2017
	drop if doentry>d(31dec2016)
	tab exposed /*96k  with cancer*/
	
	stcox exposed, strata(set) iterate(1000)

	
	
	
	*12 months follow-up after indexdate
	gen fup=(doendcprdfup-doentry)/365.25
	sum fup
	drop if fup<1 & exposed==1	
	tab exposed /*60k  with cancer*/
	
	stcox exposed, strata(set) iterate(1000)
	drop if fup<1 & exposed==0
	stcox exposed, strata(set) iterate(1000)

	
	* patients alive and still registered to UTS practices within CPRD GOLD at age 65
	gen date_65=dob+(365.25*65)
	format date_65 %td
	list doentry  doend dob date_65  in 1/25
	
	gen age65criteria=1 if dostart<=date_65 & doendcprdfup>date_65
	keep if age65criteria==1
	tab exposed /*27k  with cancer*/
	
	sum age if exposed==1, d /*68 years*/
	sum age if exposed==0, d 
	
	stcox exposed, strata(set) iterate(1000)

	
	*exclude those with Cancer diagnosis and dementia within one year of each other
	gen time_to_dx=(main0_datedementia-doentry)/365.25
	sum time_to_dx if exposed==1, d
	drop if time_to_dx<=1 & exposed==1
	tab exposed /*25k  with cancer*/
	
	stcox exposed, strata(set) iterate(1000)

	drop if time_to_dx<=1 
	tab exposed /*27k  with cancer*/
	
	stcox exposed, strata(set) iterate(1000)

	