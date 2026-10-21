*Author name: Harriet Forbes
*Date: 28th July 2026
*Purpose: Check number of controls who later become cases

use "$datafiles_an_dem/cr_dataforDEManalysis_aandg.dta", clear

* Flag whether each patient ever appears as unexposed or exposed
bysort e_patid: egen ever_unexposed = max(exposed == 0)
bysort e_patid: egen ever_exposed   = max(exposed == 1)

* Tag one observation per patient
egen patient_tag = tag(e_patid)

* Count unique patients with both statuses
codebook e_patid if ever_unexposed == 1 & ever_exposed == 1
