cap log close

/***** COX MODEL ESTIMATES FOR CRUDE, ADJUSTED AND SENSITIVITY ANALYSES ****/
local year 1
local site bre
local db aandg
local outcome dementia
global datafiles_an_preg "Z:\GPRD_GOLD\Krishnan\20_000268\20_000268_3rd_Delivery (pregnancy register)\20_000268_PregReg_HESMaternity_Delivery\datafiles\pregnancy_after_cancer\"

use "$datafiles_an_dem/cr_dataforDEManalysis_`db'_`site'.dta", clear 
	drop if index_year<2012
	tab exposed
	
	*Merge in ER_status data 
	merge m:1 e_patid using "$datafiles_an_preg/cr_listpatid_breast_cancer_type", nogen keep(master match) 

	
	include "$dofiles_an_dem/inc_excludepriorandset_dementia.do" /*excludes prior specific outcomes and st sets data*/
 	
	gen exposed_er=1 if er_positive_cr==1
	replace exposed_er=2 if er_positive_cr==0
	replace exposed_er=0 if exposed==0

	tab exposed_er, miss
	
	noi stcox i.exposed_er $covariates_common, strata(set) iterate(1000)	