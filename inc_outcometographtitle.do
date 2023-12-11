
*creates locals for outcome group names

*composite / main outcomes
if "`outcome'" == "depression" local name "Depression"
if "`outcome'" == "anxiety" local name "Anxiety"
if "`outcome'" == "fatigue" local name "Fatigue"
if "`outcome'" == "cognitivedysfunction" local name "Cognitive dysfunction"
if "`outcome'" == "selfharm" local name "Self harm"
if "`outcome'" == "suicide" local name "Completed suicide"
if "`outcome'" == "sexualdysfunction" local name "Sexual Dysfunction"
if "`outcome'" == "sleepdisorder" local name "Sleep Disturbances"
if "`outcome'" == "eating_disorder" local name "Eating Disorder"
if "`outcome'" == "heavy_alc_cons" local name "Heavy Alcohol Consumption"

    

