tempname myhandle


file open `myhandle' using "$results_an_dem/an_23_SENSE_h_c_use_post_baseline.txt", write  replace 
 foreach db of  global databases {
	foreach cancersite of global cancersites {
		
	use "$datafiles_an_dem/cr_dataforDEManalysis_`db'_`cancersite'.dta", clear 
	file write `myhandle' _n "`cancersite'" _tab 

	
	merge 1:1 e_patid setid using "${datafiles}/listpat_no_cons_year_post_index_Aurum", keep(master match) nogen
	merge 1:1 e_patid setid using "${datafiles}/listpat_no_cons_year_post_index_GOLD", keep(master match) nogen
	
	sum cons_post_index_per_year cons_post_index_per_year_gr
	recode cons_post_index_per_year .=0
	recode cons_post_index_per_year_gr .=0
	
	foreach x in 1 0 {
	sum cons_post_index_per_year if exposed==`x', d
	local median=`r(p50)'
	local p25=`r(p25)'
	local p75=`r(p75)'
	file write `myhandle' %4.1f (`median') " (" %4.1f (`p25') "-" %4.1f (`p75') ")" _tab
	}
	 
	}
 }
 file close `myhandle'
