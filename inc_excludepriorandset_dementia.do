
*drop individuals with outcome event prior to index date and create stset variables

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
replace doexit = censordatecontrol if doexit>=censordatecontrol
format censordatecontrol %td


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


cap drop dementia
if "`outcome'"=="alz" {
gen dementia= 1 if main0_datedementia<= doexit & dem_typedementia==1   
}

if "`outcome'"=="vasc" {
gen dementia= 1 if main0_datedementia<= doexit & dem_typedementia==2    
}

if "`outcome'"=="other_dem" {
gen dementia= 1 if main0_datedementia<= doexit & (dem_typedementia==3 | dem_typedementia==4 | dem_typedementia==5 | dem_typedementia==6)      
}

if "`outcome'"=="ns_dem" {
gen dementia= 1 if main0_datedementia<= doexit & dem_typedementia==7      
}

if "`outcome'"=="dementia" {
gen dementia= 1 if main0_datedementia<= doexit
}

if "`outcome'"=="dementiaspec" {
gen dementia= 1 if main0_datedementiaspec<= doexit
}

tab dementia exposed		
*create unique id value to account for patients who are both in the control and control groups
sort e_patid exposed
gen id = _n
stset doexit, id(id) failure(dementia = 1) enter(doentry) origin(doentry) exit(doexit) scale(365.25)
