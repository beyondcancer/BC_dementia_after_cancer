
/*************************************************************************
20_000268 
/***************************************************************************
DEMENTIA ANALYSIS
***************************************************************************/
***************************************************************************/

*Generate dementia outcome variable and history of
do "C:\Github\BC_data_management\2 variable generation\cr_all_events_dementia_gold.do"
do "C:\Github\BC_data_management\2 variable generation\cr_all_events_dementia_Aurum.do"
 
do "C:\Github\BC_data_management\2 variable generation\cr_listpat_dementia_gold.do"
do "C:\Github\BC_data_management\2 variable generation\cr_listpat_dementia_aurum.do"


*Generate main dataset and datasets for sense analysis
do "$dofiles_an_dem\0_cr_dataforDEManalysis_GOLD.do"
do "$dofiles_an_dem\0_cr_dataforDEManalysis_Aurum.do"
do "$dofiles_an_dem\0_cr_dataforDEManalysis_AandG.do"

do "$dofiles_an_dem\0_cr_dataforSENSE_DEManalysis_GOLD.do"
do "$dofiles_an_dem\0_cr_dataforSENSE_DEManalysis_Aurum.do"
do "$dofiles_an_dem\0_cr_dataforSENSE_DEManalysis_AandG.do"

do "$dofiles_an_dem\0_cr_dataforSENSE_histdem_DEManalysis_GOLD.do"
do "$dofiles_an_dem\0_cr_dataforSENSE_histdem_DEManalysis_Aurum.do"
do "$dofiles_an_dem\0_cr_dataforSENSE_histdem_DEManalysis_AandG.do"

do "$dofiles_an_dem\0_cr_dataforSENSEpricare_DEManalysis_GOLD.do"
do "$dofiles_an_dem\0_cr_dataforSENSEpricare_DEManalysis_Aurum.do"
do "$dofiles_an_dem\0_cr_dataforSENSEpricare_DEManalysis_AandG.do"

/***************************************************************************
        DESCRIPTIVE ANALYSIS        
***************************************************************************/
**** BASELINE CHARACTERISTICS
* Manuscript table 1
do "$dofiles_an_dem\an_1covariates_tables_manuscript.do"

*Number in each analysis

*Appendix tables for site-specific
do "$dofiles_an_dem\an_2covariates_tables_by_site_appendix.do"


/***************************************************************************
MAIN ANALYSIS
***************************************************************************/
*Generate incidences
do "$dofiles_an_dem/an_3Primary_A1_crude-incidence_nofailures_dementia.do"

*Run main models
do "$dofiles_an_dem/an_4Primary_A2_cox-model-estimates_dementia.do" 
do "$dofiles_an_dem/an_5Primary_A2_cox-model-estimates_processout_dementia.do" /*save estimates in stata file*/

*Figures 
do "$dofiles_an_dem/an_6Primary_A1A2_main figure_dementia.do" 

***INTERACTIONS****
do "$dofiles_an_dem\an_7Primary_A2_cox-model-estimates_int_dementia.do"
do "$dofiles_an_dem\an_7Primary_A2_rawnumbers_int_dementia.do"
do "$dofiles_an_dem\an_8Primary_A2_cox-model-estimates_int_processout_dementia.do"
do "$dofiles_an_dem\an_9Primary_A2_cox-model-figures-interactions_dementia.do"

/***************************************************************************
SECONDARY ANALYSIS
***************************************************************************/
****STAGE****
do "$dofiles_an_dem\an_10Secondary_A2_cox-model-estimates-stage.do"
do "$dofiles_an_dem\an_11Secondary_A2_cox-model-estimates_processout-stage.do"
do "$dofiles_an_dem\an_12Secondary_A2_figure-stage.do"

***TIME SINCE DX****
do "$dofiles_an_dem\an_13Secondary_timesinceDx_cox-model-estimates.do" 
do "$dofiles_an_dem\an_14Secondary_timesinceDx_cox-model-estimates_process_out.do"	
do "$dofiles_an_dem\an_15Secondary_timesinceDx_cox-model-estimates-figures.do"

/**TREATMENT
do "$dofiles_an_dem\an_16Secondary_A2_cox-model-estimates-trt.do"
do "$dofiles_an_dem\an_17Secondary_A2_cox-model-estimates_processout-trt.do"
do "$dofiles_an_dem\an_18Secondary_A2_figure-trt.do"*/


****IN MEDIUM-LONG-TERM CANCER SURVIVORS*****
do "$dofiles_an_dem\an_18Secondary_cox_models_risk-over-time.do"
do "$dofiles_an_dem\an_19_process_out_risk-over-time.do"
do "$dofiles_an_dem\an_19a_figure-risk_over_time.do"


***SENSE ANALYSES****
do "$dofiles_an_dem/an_4Primary_A2_cox-model-estimates_dementia_SENSE_specificdemdx.do" 
do "$dofiles_an_dem\an_20_cox-model-sensitivity-analyses2.do"
do "$dofiles_an_dem\an_20_cox-model-sensitivity-analyses.do"
do "$dofiles_an_dem\an_20_cox-model-sensitivity-analyses3-pricare.do"
do "$dofiles_an_dem\an_20_cox-model-sensitivity-analyses4-stroke.do"
do "$dofiles_an_dem\an_21_cox-model-sensitivity-analyses-process-out.do"
do "$dofiles_an_dem\an_22cr_forest_sensitivity.do"

*Odds of having a history of dementia at cancer diagnosis
do "$dofiles_an_dem\an_23_SENSE_odds_exc_h_o_dementia.do"

*Exploratory
*With estimates unaccounted for matched set (crude)
do "$dofiles_an_dem/an_X_main figure_dementia_with_crude.do"
