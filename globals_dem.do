

global datafiles_raw "Z:\GPRD_GOLD\Krishnan\20_000268\20_000268_2nd_Delivery (full data)\datafiles/"
global datafiles_core "Z:\GPRD_GOLD\Krishnan\20_000268\20_000268_2nd_Delivery (full data)\datafiles/cr_coredataset/"
global datafiles_an_dem "Z:\GPRD_GOLD\Krishnan\20_000268\20_000268_2nd_Delivery (full data)\datafiles\dementia"
global logfiles_an_dem "J:\EHR-Working\Krishnan\20_000268\logfiles\Dementia"
global results_an_dem "J:\EHR-Working\Krishnan\20_000268\results\dementia"
global dofiles_an_dem "C:\Github\BC_dementia_after_cancer"


global outcomes "dementia"
*global outcomes_test "depression"
*global outcomes_with_definite "selfharm anxiety  depression"
*global outcomes_no_suicide "selfharm anxiety  depression "
global covariates_common "i.imd5 i.smokstatus i.alcohol_prob b_diab b_cvd b_hyp b_ckd b_depression "
global databases "AandG"

*Cancer sites
global cancersitesalph "bla bre cer col cns gas kid leu liv lun mel mye nhl oes ora ova pan pro thy ute" /*alphabetical*/
global cancersites "ora oes gas col liv pan lun mel bre cer ute ova pro kid bla cns thy nhl mye leu" /*ICD10 order*/
global cancersites_cns_b "ora oes gas col liv pan lun mel bre cer ute ova pro kid bla cns cns_b thy nhl mye leu" /*with benign CNS*/
global cancersites5yrsurv "pan liv lun cns oes gas ora leu bla ova mye  col  nhl kid cer ute bre thy  pro mel" /*5-year survival order*/
global cancersites_female "ora oes gas col liv pan lun mel bre cer ute ova kid bla cns thy nhl mye leu" /*prostate removed*/
global top9cancers "col lun mel bre ute pro bla nhl leu"
global cancersites_bre "bre" 
global cancersites_pan "pan" 
global cancersites_mel "mel" 