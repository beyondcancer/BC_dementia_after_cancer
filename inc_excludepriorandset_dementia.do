
*drop individuals with outcome event prior to index date and create stset variables
*results may not be generalisable to risk of recurrent specific CVD events

drop if main0_datedementia <= indexdate+(365.25*`year')
rename indexdate doentry
replace doentry=doentry +(365.25*`year')		

*Note: doendcprdfup=min(lcd,tod,deathdate,dod, enddate), where enddate includes date of 
*cancer diagnosis in controls
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

cap drop dementia
if "`outcome'"=="alz" {
gen dementia= 1 if main0_datedementia<= doexit & dem_typedementia==1   
}

if "`outcome'"=="vasc" {
gen dementia= 1 if main0_datedementia<= doexit & dem_typedementia==2    
}

if "`outcome'"=="other_dem" {
gen dementia= 1 if main0_datedementia<= doexit & (dem_typedementia==2  | dem_typedementia==3 | dem_typedementia==4 | dem_typedementia==5 | dem_typedementia==6)      
}

if "`outcome'"=="ns_dem" {
gen dementia= 1 if main0_datedementia<= doexit & dem_typedementia==7      
}

if "`outcome'"=="dementia" {
gen dementia= 1 if main0_datedementia<= doexit
}

if "`outcome'"=="dementiahes" {
gen dementia= 1 if main0_datedementiahes<= doexit
}

if "`outcome'"=="drugsdementia" {
gen dementia= 1 if main0_datedementiadrugs<= doexit
}
		
*create unique id value to account for patients who are both in the control and control groups
sort e_patid exposed
gen id = _n
stset doexit, id(id) failure(dementia = 1) enter(doentry) origin(doentry) exit(doexit) scale(365.25)
