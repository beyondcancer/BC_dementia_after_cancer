********************************************************************************
*graphs
********************************************************************************

set trace off

foreach cancersite of global cancersites {
	use "$results_an_dem/an_stpm2_cum_predictedincidences_allcancers_cis", clear
keep if cancer== "`cancersite'" 

 if cancer=="ora"	local cancersite2="Oral cavity (C00-06)"    
 if cancer=="oes"	local cancersite2="Oesophageal (C15)"	 	  
 if cancer=="gas"	local cancersite2="Stomach (C16)" 		  
  if cancer=="col"	local cancersite2="Colorectal (C18-20)"    
 if cancer=="liv"	local cancersite2="Liver (C22)"		  	  
  if cancer=="pan"	local cancersite2="Pancreas (C25)"		   
  if cancer=="lun"	local cancersite2="Lung (C34)"  		  	  
  if cancer=="mel"	local cancersite2="Malignant melanoma (C43)" 
  if cancer=="bre"	local cancersite2="Breast (C50)" 		 
  if cancer=="cer"	local cancersite2="Cervix (C53)" 		
  if cancer=="ute"	local cancersite2="Uterus (C54-55)" 	  	  
  if cancer=="ova"	local cancersite2="Ovary (C56)" 		  	 
  if cancer=="pro"	local cancersite2="Prostate (C61)"		 
  if cancer=="kid"	local cancersite2="Kidney (C64)" 		  	  
  if cancer=="bla"	local cancersite2="Bladder (C67)" 		
  if cancer=="cns"	local cancersite2="CNS (C71-72)" 		  	  
  if cancer=="thy"	local cancersite2="Thyroid (C73)" 		 
  if cancer=="nhl"	local cancersite2="NHL (C82-85)" 		  	
  if cancer=="mye"	local cancersite2="Multiple myeloma (C90)"   
  if cancer=="leu"	local cancersite2="Leukaemia (C91-95)"   	   
	

foreach cancer in "Oral cavity (C00-06)" "Oesophageal (C15)" "Stomach (C16)" "Colorectal (C18-20)" "Liver (C22)" "Pancreas (C25)" "Lung (C34)" "Malignant melanoma (C43)" "Breast (C50)" "Cervix (C53)" "Uterus (C54-55)" "Ovary (C56)" "Prostate (C61)" "Kidney (C64)" "Bladder (C67)" "CNS (C71-72)" "Thyroid (C73)" "NHL (C82-85)" "Multiple myeloma (C90)" "Leukaemia (C91-95)" {
	
	if "`cancer'"=="Oral cavity (C00-06)" local namegraph="ora"
	if "`cancer'"=="Oesophageal (C15)" local namegraph="oes"	
	if "`cancer'"=="Stomach (C16)"  local namegraph="gas"
	if "`cancer'"=="Colorectal (C18-20)" local namegraph="col"
	if "`cancer'"=="Liver (C22)" local namegraph="liv"
	if "`cancer'"=="Pancreas (C25)" local namegraph="pan"
	if "`cancer'"=="Lung (C34)" local namegraph="lun"
	if "`cancer'"=="Malignant melanoma (C43)" local namegraph="mel"
	if "`cancer'"=="Breast (C50)" local namegraph="bre"
	if "`cancer'"=="Cervix (C53)" local namegraph="cer"
	if "`cancer'"=="Uterus (C54-55)" local namegraph="ute"
	if "`cancer'"=="Ovary (C56)" local namegraph="ova"
	if "`cancer'"=="Prostate (C61)" local namegraph="pro"
	if "`cancer'"=="Kidney (C64)" local namegraph="kid"
	if "`cancer'"=="Bladder (C67)" local namegraph="bla"
	if "`cancer'"=="CNS (C71-72)" local namegraph="cns"
	if "`cancer'"=="Thyroid (C73)" local namegraph="thy"
	if "`cancer'"=="NHL (C82-85)" local namegraph="nhl"
	if "`cancer'"=="Multiple myeloma (C90)" local namegraph="mye"
	if "`cancer'"=="Leukaemia (C91-95)" local namegraph="leu"	
}	

twoway  (rarea exp1_lci exp1_uci date, color(red%25))  ///
			(rarea exp0_lci exp0_uci date, color(blue%25)) ///
			(line exp1 date, sort lcolor(red)  lwidth(vthin)) ///
			(line exp0 date, sort lcolor(blue)  lwidth(vthin)) ///
			 ,  legend(off) xtitle("",)  ///
			 ylabel(0 (10) 30,angle(h) format(%3.0f) labsize(tiny)) xlabel(0(1)10, labsize(tiny)) ///
			title("`cancersite2'", size(small)) ///
			ytitle("Incidence (per 1000 person years)", size(vsmall)) ///
			 xtitle("Time since cancer diagnosis (years)", size(vsmall)) ///
			 graphregion(color(white)) 
			 
	graph save "Graph" "$results_an_dem\stpm2cumrisk_`cancersite'.gph", replace
	graph export "$results_an_dem\stpm2cumrisk_`cancersite'.pdf", as(pdf) name("Graph") replace
	list cancer* in 1/1 
}

graph combine  "$results_an_dem\stpm2cumrisk_ora.gph" "$results_an_dem\stpm2cumrisk_oes.gph" "$results_an_dem\stpm2cumrisk_gas.gph" "$results_an_dem\stpm2cumrisk_col.gph" "$results_an_dem\stpm2cumrisk_liv.gph" "$results_an_dem\stpm2cumrisk_pan.gph" "$results_an_dem\stpm2cumrisk_lun.gph" "$results_an_dem\stpm2cumrisk_mel.gph" "$results_an_dem\stpm2cumrisk_bre.gph" "$results_an_dem\stpm2cumrisk_cer.gph" "$results_an_dem\stpm2cumrisk_ute.gph" "$results_an_dem\stpm2cumrisk_ova.gph" "$results_an_dem\stpm2cumrisk_pro.gph" "$results_an_dem\stpm2cumrisk_kid.gph" "$results_an_dem\stpm2cumrisk_bla.gph" "$results_an_dem\stpm2cumrisk_cns.gph" "$results_an_dem\stpm2cumrisk_thy.gph" "$results_an_dem\stpm2cumrisk_nhl.gph" "$results_an_dem\stpm2cumrisk_mye.gph" "$results_an_dem\stpm2cumrisk_leu.gph"

graph export "$results_an_dem\Forest_cumincid_all.png", width(8000) height(6000) replace name("Graph")

/*legend(order(1 "No hist. mental illness" 2 "Hist. mental illness" 5 "No cancer" 6 "Cancer survivors" 7 "No cancer" 8 "Cancer survivors") ring(0) cols(6) pos(11) size(tiny)) ///
 ytitle("Cumulative risk (%)", size(vsmall) placement(w)) ///
 xtitle("Time since cancer diagnosis (years)", size(vsmall)) 
			 