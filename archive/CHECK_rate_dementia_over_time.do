	use "$datafiles_an_dem/cr_dataforDEManalysis_aandg_bre.dta", clear 
	tab exposed	
	*Apply outcome specific exclusions
	*dib "`cancersite' `outcome' `db'", stars
	local outcome dementia
	local year 0
	include "$dofiles_an_dem/inc_excludepriorandset_dementia.do" /*excludes prior specific outcomes and st sets data*/
	stsplit year, after(time = mdy(1,1,1960)) at(37(1)62)
replace year = year+1960

strate year if exposed==1,per(100) graph 
strate year if exposed==0, per(100) graph 