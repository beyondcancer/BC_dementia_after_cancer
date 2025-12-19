	*Merge surgery records from CR and OPCS
	use "$datafiles/cr_list_patid_surg_opcs_aurum", clear
	append using "$datafiles/cr_list_patid_surg_opcs_gold"
	save "$datafiles_an_dem/cr_list_patid_surg_opcs_aandg", replace
	
	use "$datafiles/cr_list_patid_surg_cr_aurum"
	append using "$datafiles/cr_list_patid_surg_cr_gold"
	save "$datafiles_an_dem/cr_list_patid_surg_cr_aandg", replace
