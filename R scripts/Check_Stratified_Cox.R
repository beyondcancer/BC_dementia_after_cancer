# ==============================================================================
# Script Name:           Check_Stratified_Cox.R
#
# Date:                  16 08 2024
# ==============================================================================
# install package "haven", "dplyr", "survival" if not previously installed
install.packages("haven")
install.packages("dplyr")
install.packages("survival")

# Load necessary libraries
library(haven)  # For reading STATA .dta files
library(dplyr)  # For data manipulation
library(survival) # For survival analysis

# Load the dementia dataset (.dta file) into R 
file_path <- "Z:/GPRD_GOLD/Krishnan/20_000268/20_000268_2nd_Delivery (full data)/datafiles/dementia/cr_dataforDEManalysis_aandg_lun_for_r.dta" # define the file path you stored your .dta file
core_dataset <- read_dta(file_path) # name your dataframe as core_dataset after reading into R

# Define the survival object
# replace "time_at_risk" with your follow_up time variable name and "failure" with your event variable name
surv_object <- Surv(time = core_dataset$stata_t, event = core_dataset$dementia)

# Fit the Cox proportional hazards model with multiple covariates and stratification
# ==============================================================================
# Adjust your exposure and covariates in the following section: put categorical variable within factor, contiuous variable can stay as it is
# factor(exposed_bre) + age (use factor(age_cat) if categorical) + factor(imd5) + factor(smokstatus) + 
# factor(alcohol_prob) + factor(b_diab) + factor(b_hypertension) + factor(b_ra) + 
# factor(ckdwstage) + factor(b_cvdgrouped) + factor(bmi_cat6) + factor(b_autoimmunegrouped) + 
# ==============================================================================

cox_model_unadj <- coxph(
  surv_object ~ factor(exposed),
  data = core_dataset
)

cox_model_minadj <- coxph(
  surv_object ~ factor(exposed) + 
    strata(setid),
  data = core_dataset
)

cox_model_adjusted <- coxph(
  surv_object ~ factor(exposed) + age + factor(imd5) + factor(smokstatus) + 
    factor(alcohol_prob) + factor(b_diab) + factor(b_hypertension) + factor(b_ra) + 
    factor(ckdwstage) + factor(b_cvdgrouped) + factor(bmi_cat6) + factor(b_autoimmunegrouped) + 
    strata(setid),
  data = core_dataset
)

# Print the summary of the model to get hazard ratios, confidence intervals, and p-values

summary_cox_model_unadj <- summary(cox_model_unadj)
print(summary(cox_model_unadj)) 

summary_cox_model_minadj <- summary(cox_model_minadj)
print(summary(cox_model_minadj)) 

summary_cox_model_adjusted <- summary(cox_model_adjusted)
print(summary(cox_model_adjusted)) 
# The result will show in your console and it will also tell how many participants were included in the cox model and how many events occurred
# For example:  n= 148168, number of events= 4298 (9634222 observations deleted due to missingness)

