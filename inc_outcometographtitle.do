
*creates locals for outcome group names
       
*composite / main outcomes
if "`outcome'" == "dem_all" local name "Dementia"
if "`outcome'" == "vasc" local name "Vascular dementia"
if "`outcome'" == "alz" local name "Alzheimer's"
if "`outcome'" == "other_dem" local name "Other dementia"
if "`outcome'" == "ns_dem" local name "Unspecified dementia"
if "`outcome'" == "dem_drugs" local name "Dementia (drugs)"
if "`outcome'" == "dem_hes" local name "Dementia (HES only)"


    

