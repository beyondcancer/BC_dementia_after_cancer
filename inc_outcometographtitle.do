
*creates locals for outcome group names
       
*composite / main outcomes
if "`outcome'" == "dem_all" local outcomename "Dementia"
if "`outcome'" == "vasc" local outcomename "Vascular dementia"
if "`outcome'" == "alz" local outcomename "Alzheimer's"
if "`outcome'" == "other_de" local outcomename "Other dementia"
if "`outcome'" == "ns_dem" local outcomename "Unspecified dementia"
if "`outcome'" == "dem_drugs" local outcomename "Dementia (drugs)"
if "`outcome'" == "dem_hes" local outcomename "Dementia (HES only)"


    

