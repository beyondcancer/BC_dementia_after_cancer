*Author: Harriet Forbes
*Date: 24th June 2026

/* Aim:
Calculate e-values to estimate how strong an unmeasured confounder's association 
with both cancer and dementia would need to be to explain away the 
observed cancer–dementia associations
*/

* Install evalue if needed
capture which evalue
if _rc ssc install evalue

help evalue

cd "$results_an_dem"

* Folder for E-value figures
capture mkdir "evalue_figures"

*------------------------------------------------------------
* E-values for Figure 1 adjusted HRs
* Saves point-estimate E-value and CI E-value into a table
* Also saves each E-value figure
*------------------------------------------------------------

tempname results
postfile `results' ///
    str25 cancer ///
    double hr lcl ucl evalue_est evalue_ci ///
    using "evalue_results.dta", replace


* Oral cavity
evalue hr 0.99, lcl(0.89) ucl(1.11) true(1) common figure(title("Oral cavity") xtitle(, size(vsmall)) ytitle(, size(vsmall)))
post `results' ("Oral cavity") (0.99) (0.89) (1.11) (r(eval_est)) (r(eval_ci))
graph save "oral_cavity.gph", replace
graph export "oral_cavity.png", replace

* Oesophageal
evalue hr 0.99, lcl(0.88) ucl(1.11) true(1) common figure(title("Oesophageal") xtitle(, size(vsmall)) ytitle(, size(vsmall)))
post `results' ("Oesophageal") (0.99) (0.88) (1.11) (r(eval_est)) (r(eval_ci))
graph save "oesophageal.gph", replace
graph export "oesophageal.png", replace

* Stomach
evalue hr 1.06, lcl(0.95) ucl(1.17) true(1) common figure(title("Stomach") xtitle(, size(vsmall)) ytitle(, size(vsmall)))
post `results' ("Stomach") (1.06) (0.95) (1.17) (r(eval_est)) (r(eval_ci))
graph save "stomach.gph", replace
graph export "stomach.png", replace

* Colorectal
evalue hr 0.96, lcl(0.93) ucl(0.99) true(1) common figure(title("Colorectal") xtitle(, size(vsmall)) ytitle(, size(vsmall)))
post `results' ("Colorectal") (0.96) (0.93) (0.99) (r(eval_est)) (r(eval_ci))
graph save "colorectal.gph", replace
graph export "colorectal.png", replace

* Liver
evalue hr 1.27, lcl(1.06) ucl(1.52) true(1) common figure(title("Liver") xtitle(, size(vsmall)) ytitle(, size(vsmall)))
post `results' ("Liver") (1.27) (1.06) (1.52) (r(eval_est)) (r(eval_ci))
graph save "liver.gph", replace
graph export "liver.png", replace

* Pancreas
evalue hr 1.38, lcl(1.18) ucl(1.61) true(1) common figure(title("Pancreas") xtitle(, size(vsmall)) ytitle(, size(vsmall)))
post `results' ("Pancreas") (1.38) (1.18) (1.61) (r(eval_est)) (r(eval_ci))
graph save "pancreas.gph", replace
graph export "pancreas.png", replace

* Lung
evalue hr 1.43, lcl(1.36) ucl(1.50) true(1) common figure(title("Lung") xtitle(, size(vsmall)) ytitle(, size(vsmall)))
post `results' ("Lung") (1.43) (1.36) (1.50) (r(eval_est)) (r(eval_ci))
graph save "lung.gph", replace
graph export "lung.png", replace

* Malignant melanoma
evalue hr 0.90, lcl(0.85) ucl(0.95) true(1) common figure(title("Malignant melanoma") xtitle(, size(vsmall)) ytitle(, size(vsmall)))
post `results' ("Malignant melanoma") (0.90) (0.85) (0.95) (r(eval_est)) (r(eval_ci))
graph save "malignant_melanoma.gph", replace
graph export "malignant_melanoma.png", replace

* Breast
evalue hr 1.00, lcl(0.98) ucl(1.03) true(1) common figure(title("Breast") xtitle(, size(vsmall)) ytitle(, size(vsmall)))
post `results' ("Breast") (1.00) (0.98) (1.03) (r(eval_est)) (r(eval_ci))
graph save "breast.gph", replace
graph export "breast.png", replace
 
* Cervix
evalue hr 0.95, lcl(0.77) ucl(1.16) true(1) common figure(title("Cervix") xtitle(, size(vsmall)) ytitle(, size(vsmall)))
post `results' ("Cervix") (0.95) (0.77) (1.16) (r(eval_est)) (r(eval_ci))
graph save "cervix.gph", replace
graph export "cervix.png", replace

* Uterus
evalue hr 0.94, lcl(0.88) ucl(1.00) true(1) common figure(title("Uterus") xtitle(, size(vsmall)) ytitle(, size(vsmall)))
post `results' ("Uterus") (0.94) (0.88) (1.00) (r(eval_est)) (r(eval_ci))
graph save "uterus.gph", replace
graph export "uterus.png", replace

* Ovary
evalue hr 0.94, lcl(0.84) ucl(1.04) true(1) common figure(title("Ovary") xtitle(, size(vsmall)) ytitle(, size(vsmall)))
post `results' ("Ovary") (0.94) (0.84) (1.04) (r(eval_est)) (r(eval_ci))
graph save "ovary.gph", replace
graph export "ovary.png", replace

* Prostate
evalue hr 1.11, lcl(1.08) ucl(1.13) true(1) common figure(title("Prostate") xtitle(, size(vsmall)) ytitle(, size(vsmall)))
post `results' ("Prostate") (1.11) (1.08) (1.13) (r(eval_est)) (r(eval_ci))
graph save "prostate.gph", replace
graph export "prostate.png", replace

* Kidney
evalue hr 1.10, lcl(1.02) ucl(1.19) true(1) common figure(title("Kidney") xtitle(, size(vsmall)) ytitle(, size(vsmall)))
post `results' ("Kidney") (1.10) (1.02) (1.19) (r(eval_est)) (r(eval_ci))
graph save "kidney.gph", replace
graph export "kidney.png", replace

* Bladder
evalue hr 1.06, lcl(1.01) ucl(1.12) true(1) common figure(title("Bladder") xtitle(, size(vsmall)) ytitle(, size(vsmall)))
post `results' ("Bladder") (1.06) (1.01) (1.12) (r(eval_est)) (r(eval_ci))
graph save "bladder.gph", replace
graph export "bladder.png", replace

* Brain/CNS
evalue hr 3.06, lcl(2.47) ucl(3.80) true(1) common figure(title("Brain/CNS") xtitle(, size(vsmall)) ytitle(, size(vsmall)))
post `results' ("Brain/CNS") (3.06) (2.47) (3.80) (r(eval_est)) (r(eval_ci))
graph save "brain_cns.gph", replace
graph export "brain_cns.png", replace

* Thyroid
evalue hr 0.84, lcl(0.70) ucl(1.02) true(1) common figure(title("Thyroid") xtitle(, size(vsmall)) ytitle(, size(vsmall)))
post `results' ("Thyroid") (0.84) (0.70) (1.02) (r(eval_est)) (r(eval_ci))
graph save "thyroid.gph", replace
graph export "thyroid.png", replace

* NHL
evalue hr 1.02, lcl(0.96) ucl(1.08) true(1) common figure(title("NHL") xtitle(, size(vsmall)) ytitle(, size(vsmall)))
post `results' ("NHL") (1.02) (0.96) (1.08) (r(eval_est)) (r(eval_ci))
graph save "nhl.gph", replace
graph export "nhl.png", replace

* Multiple myeloma
evalue hr 1.42, lcl(1.30) ucl(1.55) true(1) common figure(title("Multiple myeloma") xtitle(, size(vsmall)) ytitle(, size(vsmall)))
post `results' ("Multiple myeloma") (1.42) (1.30) (1.55) (r(eval_est)) (r(eval_ci))
graph save "multiple_myeloma.gph", replace
graph export "multiple_myeloma.png", replace

* Leukaemia
evalue hr 1.04, lcl(0.96) ucl(1.13) true(1) common figure(title("Leukaemia") xtitle(, size(vsmall)) ytitle(, size(vsmall)))
post `results' ("Leukaemia") (1.04) (0.96) (1.13) (r(eval_est)) (r(eval_ci))
graph save "leukaemia.gph", replace
graph export "leukaemia.png", replace


* Close the results file
postclose `results'

*------------------------------------------------------------
* Open and format the table
*------------------------------------------------------------

use "evalue_results.dta", clear

format hr lcl ucl %5.2f
format evalue_est evalue_ci %6.3f

list cancer hr lcl ucl evalue_est evalue_ci, noobs sep(0)


*------------------------------------------------------------
* Export table
*------------------------------------------------------------

export delimited using "evalue_results.csv", replace

*------------------------------------------------------------
* Combine all E-value figures onto one page
*------------------------------------------------------------

graph combine ///
    "oral_cavity.gph" ///
    "oesophageal.gph" ///
    "stomach.gph" ///
    "colorectal.gph" ///
    "liver.gph" ///
    "pancreas.gph" ///
    "lung.gph" ///
    "malignant_melanoma.gph" ///
    "breast.gph" ///
    "cervix.gph", ///
    cols(4) ///
    imargin(tiny) ///
    graphregion(color(white)) ///
    title("E-value curves by cancer type")

graph save "evalue_all_cancers_combined_1.gph", replace

graph export "evalue_all_cancers_combined_1.png", ///
    replace width(4000)
	
	graph combine ///
    "uterus.gph" ///
    "ovary.gph" ///
    "prostate.gph" ///
    "kidney.gph" ///
    "bladder.gph" ///
    "brain_cns.gph" ///
    "thyroid.gph" ///
    "nhl.gph" ///
    "multiple_myeloma.gph" ///
    "leukaemia.gph", ///
    cols(4) ///
    imargin(tiny) ///
    graphregion(color(white)) ///
    title("E-value curves by cancer type")

graph save "evalue_all_cancers_combined_2.gph", replace

graph export "evalue_all_cancers_combined_2.png", ///
    replace width(4000)