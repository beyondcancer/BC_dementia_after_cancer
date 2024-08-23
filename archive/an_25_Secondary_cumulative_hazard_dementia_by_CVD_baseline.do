
foreach year in 0 {
foreach cancersite of global cancersites {
foreach outcome in dementia {

use "$datafiles_an_dem/cr_dataforDEManalysis_aandg_`cancersite'.dta", clear 
	
	include "$dofiles_an_dem/inc_excludepriorandset_dementia.do"	 


		*sts graph if b_cvd==1, by(exposed) haz 
		*sts graph if b_cvd==0, by(exposed) haz 
		*sts graph, by(exposed b_cvd) cumhaz legend (size(tiny))
		
		sts graph, by(exposed b_cvd) cumhaz tmax(5) saving("$results_an_dem/km_`outcome'_`cancersite'_cvd", replace) title("`cancersite'") yscale(range(0 0.1)) legend(off)
		
}
}
}

cd "$results_an_dem"

graph combine  km_dementia_ora_cvd.gph km_dementia_oes_cvd.gph km_dementia_gas_cvd.gph km_dementia_col_cvd.gph km_dementia_liv_cvd.gph km_dementia_pan_cvd.gph km_dementia_lun_cvd.gph km_dementia_mel_cvd.gph km_dementia_bre_cvd.gph km_dementia_cer_cvd.gph km_dementia_ute_cvd.gph km_dementia_ova_cvd.gph km_dementia_pro_cvd.gph km_dementia_kid_cvd.gph km_dementia_bla_cvd.gph km_dementia_cns_cvd.gph km_dementia_thy_cvd.gph km_dementia_nhl_cvd.gph km_dementia_mye_cvd.gph km_dementia_leu_cvd.gph
 
 
 /*legend(label(1 "Comparators without CVD") label(3 "Cancer survivors without CVD at baseline") label(2 "Comparators with CVD at baseline") label(4 "Cancer survivors with CVD at baseline") size(tiny)) */
