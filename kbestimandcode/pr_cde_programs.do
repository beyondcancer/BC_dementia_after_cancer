*==============================================================================
* pr_cde_programs.do
*
* Programs for the controlled direct effect (CDE) analyses of cancer history
* and dementia. Load with:  run pr_cde_programs.do
*
*   pr_cde_grade_as_stage tumour grade in place of stage (e.g. CNS)
*   pr_cde_dataprep_grid  split follow-up on the weight-update grid (fine
*                         intervals early, annual later) and build the
*                         variables the weight models need
*   pr_cde_weights        exposure weights (IPTW, logistic; ATT or ATE:
*                         $cde_estimand) and time-updated weights for
*                         censoring by death (IPCW, discrete-time cloglog by
*                         default, or logistic: $cde_death_link)
*   pr_cde_km             CDE: exposure x death weighted Kaplan-Meier risks,
*                         risk ratios and risk differences at a list of
*                         horizons (r() scalars)
*   pr_cde_cif            total effect: exposure-weighted Aalen-Johansen
*                         cumulative incidence (death as a competing event),
*                         risk ratios and differences at the same horizons
*   pr_cde_balance        weighted covariate balance among those still at
*                         risk over follow-up: prints tables, returns max |SMD|
*
* The programs work on the data in memory and save nothing; the analysis
* files (an_cdekm.do, an_cdekm_combine.do, an_weightedCox.do) do the
* loading and saving. pr_cde_weights can store coefficient matrices
* (cde_start_*) in memory to use as start values in bootstrap replicates.
*
* Globals used (set in inc_cde_settings.do): $baseline_confounders,
* $time_varying_death_predictors, $death_time_knots, $cde_nostage,
* $cde_split_exposed_death, $cde_death_link, $cde_age_knots,
* $cde_age_stage_int, $cde_estimand, $cde_admin_end,
* $CDEKMexposureweightson, $CDEKMdeathweightson, $cde_truncation_pct,
* $cde_smd_threshold
*
* Each record (person-interval) is later stset as its OWN left-truncated
* record (no id()), so pweights are constant within "subject" while still
* changing from interval to interval.
*==============================================================================
version 18

* Code version (see inc_cde_settings.do): checked by the analysis files
global cde_programs_version "2026-10-16c"


****************************************************************************
* pr_cde_grade_as_stage
*   For cancers listed in $cde_grade_as_stage (no TNM stage, e.g. CNS),
*   replaces stage_tnm with tumour grade from $cde_grade_var (numeric:
*   1-4 = grade, 99 = GX or missing), so grade enters the exposed death
*   models (with its age interaction) and the stage balance check exactly as
*   stage does for other cancers. Does nothing for other cancers.
*   Codes used: 1 = grade 1-2 (few grade 1), 3, 4, 99 = GX or missing.
****************************************************************************
capture program drop pr_cde_grade_as_stage
program define pr_cde_grade_as_stage
syntax, cancertype(string)

	if strpos(" $cde_grade_as_stage ", " `cancertype' ") == 0 exit

	local gv $cde_grade_var
	* exact: Stata would otherwise accept an abbreviation of another variable
	capture confirm numeric variable `gv', exact
	if _rc {
		display as error "cde_grade_as_stage includes `cancertype' but there is no numeric variable `gv' in the data"
		exit 111
	}

	capture drop stage_tnm
	quietly gen byte stage_tnm = 99
	quietly replace stage_tnm = 1 if inlist(`gv', 1, 2)
	quietly replace stage_tnm = 3 if `gv' == 3
	quietly replace stage_tnm = 4 if `gv' == 4
	* Grade describes the cancer, so only on exposed records (an e_patid can
	* also appear as a comparator before their own cancer)
	quietly replace stage_tnm = 99 if exposed == 0
	label define cde_grade_lbl 1 "Grade 1-2" 3 "Grade 3" 4 "Grade 4" 99 "Grade X/missing", replace
	label values stage_tnm cde_grade_lbl

	display as text _n "Grade (`gv') used in place of stage for `cancertype'. Exposed:"
	tab `gv' stage_tnm if exposed == 1, missing
	quietly count if exposed == 1 & inlist(stage_tnm, 1, 3, 4)
	if r(N) == 0 display as error "WARNING: no exposed record has grade 1-4 - check the coding of `gv'"

end

****************************************************************************
* pr_cde_dataprep_grid
*   Expects: one row per spell (person-exposure period), as left by
*   inc_excludepriorandset_dementia.do, plus died_this_spell.
*   fine_per_year: intervals per year in the early period (4 = quarterly)
*   fine_until:    length of the early period in whole years (2)
*   After that, intervals are annual. Exact event/exit times are kept.
****************************************************************************
capture program drop pr_cde_dataprep_grid
program define pr_cde_dataprep_grid
syntax, fine_per_year(integer) fine_until(integer)

	fvrevar $baseline_confounders, list
	local confounder_vars `r(varlist)'

	local optional_vars
	foreach v in stage_tnm setid {
		capture confirm variable `v'
		if !_rc local optional_vars `optional_vars' `v'
	}

	* One id per ROW (spell). e_patid repeats when a comparator later develops
	* cancer and re-enters as exposed; e_patid is kept for clustering and the
	* bootstrap.
	capture drop record_id
	gen long record_id = _n

	* Practice last collection date, if present (for potential follow-up)
	local lcd_var
	capture confirm numeric variable lcd
	if !_rc local lcd_var lcd

	unab keep_list : record_id e_patid exposed doentry doexit dementia died_this_spell main0_datedementia ///
		`confounder_vars' `optional_vars' `lcd_var' b_* dof_*
	local keep_list : list uniq keep_list
	keep `keep_list'

	* Potential follow-up (years): time from index to the end of data
	* collection (study end $cde_admin_end, or the practice's last collection
	* date if earlier), i.e. how long a person COULD have been followed if they
	* had not died, moved or had an outcome. Used by pr_cde_balance so that the
	* exposed stage mix at time t is compared with the baseline mix among those
	* who could have been followed to t (administrative censoring by calendar
	* time is not something the death weights should, or can, correct).
	gen double potential_fu = (td($cde_admin_end) - doentry) / 365.25
	if "`lcd_var'" != "" replace potential_fu = min(potential_fu, (lcd - doentry) / 365.25) if !missing(lcd)

	quietly count if dementia == 1 & main0_datedementia != doexit
	if r(N) > 0 display as error "WARNING: " r(N) " records with dementia==1 have main0_datedementia != doexit - check event coding"

	* Analysis time = years since doentry (as in inc_excludepriorandset_dementia.do)
	quietly stset doexit, id(record_id) failure(dementia == 1) origin(time doentry) scale(365.25)
	quietly keep if _st == 1

	* Split points: every 1/fine_per_year years up to fine_until, then annual
	local cuts
	local n_fine = `fine_until' * `fine_per_year'
	forvalues k = 0/`n_fine' {
		local cuts `cuts' `=`k'/`fine_per_year''
	}
	local first_annual = `fine_until' + 1
	if `first_annual' <= 60 local cuts `cuts' `first_annual'(1)60
	quietly stsplit split_point, at(`cuts')
	drop split_point

	gen double tstart = _t0
	gen double tstop  = _t
	gen byte   event  = _d

	sort e_patid record_id tstart
	by e_patid record_id: gen int  interval_number = _n
	by e_patid record_id: gen byte last_record     = (_n == _N)
	gen int follow_up_year = floor(tstart) + 1

	* Interval type and nominal width (fine early, annual later). The death
	* models include i.fine_interval, because the probability of death in a
	* quarter and in a year differ for that reason alone.
	gen byte   fine_interval = (tstart < `fine_until' - 1e-9)
	gen double nominal_width = cond(fine_interval, 1 / `fine_per_year', 1)

	* Death outcome for the death models: final record of a spell ending in death
	gen byte died_this_interval = (died_this_spell == 1 & last_record)

	* Offset for the cloglog death model (grouped-time proportional hazards).
	* A death is an event in the interval, so a death record gets the FULL
	* nominal width (P(death within the interval)); a record that ends alive
	* part-way through (censoring, dementia) gets the time actually observed
	* (P(surviving that long)); complete intervals get the nominal width.
	* (Before 16 Oct 2026 death records used their actual, shorter width.
	* Together with time measured at each record's own midpoint, that let the
	* time spline separate deaths from survivors within each interval, so
	* P(death) for complete early intervals was badly underestimated and the
	* death weights under-corrected, most where early mortality is high.)
	gen double ln_width = ln(cond(died_this_interval, nominal_width, tstop - tstart))

	* Records used to FIT the death models (discrete-time logistic): complete
	* intervals, plus the final (possibly partial) interval of spells ending
	* in death or dementia. A censored person's final partial interval is not
	* used for fitting (the full interval was not observed), but it still gets
	* a weight, which depends only on earlier intervals.
	gen byte death_model_row = (tstop - tstart >= nominal_width - 1e-6) | ///
		(last_record & (dementia == 1 | died_this_spell == 1))

	* Time since index for the death models: restricted cubic spline at the
	* NOMINAL interval midpoint, the same for every record in an interval
	* however it ended (a time variable that depends on when the record ended
	* leaks the outcome into the model), with fixed knots (identical across
	* runs and replicates)
	gen double time_mid = tstart + nominal_width / 2
	mkspline time_rcs = time_mid, cubic knots($death_time_knots)

	* Periods for the time-varying effect of age on death (<6m, 6m-2y, 2y+),
	* and age centred at 70 and per 10 years
	gen byte   death_period = cond(time_mid < 0.5, 1, cond(time_mid < 2, 2, 3))
	gen double age_c        = (age - 70) / 10

	* Restricted cubic spline in age for the death models ($cde_age_knots
	* knots; 0 = off). Knots at Harrell's default centiles of age at the start
	* of each spell, so they are fixed for the run (identical in every
	* bootstrap replicate). age_rcs1 is age itself (already in the models);
	* the death models add the non-linear terms age_rcs2, age_rcs3, ...
	local age_spline_vars
	if $cde_age_knots > 0 {
		if      $cde_age_knots == 3 local age_centiles "10 50 90"
		else if $cde_age_knots == 4 local age_centiles "5 35 65 95"
		else if $cde_age_knots == 5 local age_centiles "5 27.5 50 72.5 95"
		else {
			display as error "cde_age_knots must be 0, 3, 4 or 5 (currently: $cde_age_knots)"
			exit 198
		}
		_pctile age if interval_number == 1, percentiles(`age_centiles')
		local age_knots
		forvalues k = 1/$cde_age_knots {
			local age_knots `age_knots' `=r(r`k')'
		}
		mkspline age_rcs = age, cubic knots(`age_knots')
		display as text "Age spline knots (death models): `age_knots'"
		local age_spline_vars age_rcs*
	}

	* Time-varying cardiovascular disease at the START of each interval (names
	* kept as *_start_of_year so existing globals still work)
	gen double interval_start_date = doentry + 365.25 * tstart
	foreach cvd_flag in af stroke mi hf arrhythmia cad pvd vte cvdgrouped {
		gen byte `cvd_flag'_start_of_year = b_`cvd_flag' if interval_number == 1
		replace  `cvd_flag'_start_of_year = (dof_`cvd_flag' <= interval_start_date) if interval_number > 1 & !missing(dof_`cvd_flag')
		replace  `cvd_flag'_start_of_year = 0 if interval_number > 1 & missing(dof_`cvd_flag')
	}

	capture stset, clear
	capture drop _st _d _t _t0

	unab final_keep : record_id e_patid exposed tstart tstop event interval_number follow_up_year last_record ///
		fine_interval nominal_width died_this_interval death_model_row ln_width time_mid time_rcs* death_period age_c ///
		`age_spline_vars' potential_fu `confounder_vars' `optional_vars' *_start_of_year
	local final_keep : list uniq final_keep
	keep `final_keep'

	* IMD fifths, for the balance checks only (weight models use twentiles):
	* 20 small categories make the SMD rule trip on noise at long horizons
	capture confirm variable imd20
	if !_rc gen byte imd5 = ceil(imd20 / 4) if !missing(imd20)

	sort e_patid record_id interval_number

	* Person index 1..n (for the bootstrap frequency draw, which then needs
	* no sorting); data are already sorted by e_patid
	by e_patid: gen long person_index = (_n == 1)
	replace person_index = sum(person_index)

	compress

	display as text "Grid: " `fine_per_year' " intervals per year for " `fine_until' " years, annual after. Records: " _N

end


****************************************************************************
* pr_cde_weights
*   Fits the exposure and death models and creates:
*     weight_exposure  inverse probability of the observed exposure
*     weight_death     inverse probability of surviving all PREVIOUS intervals
*     weight_final     weight_exposure x weight_death (for the KM)
*   bootweight(): frequency variable for a bootstrap replicate (omit for the
*   point estimate). Logits use [fweight]; records with frequency 0 are
*   excluded from fitting.
*   savestart: store each model's coefficients as matrices cde_start_*
*   usestart:  start each model from those matrices (bootstrap replicates;
*              speed only - the maximum found is the same). If a fit from
*              the start values fails, it is refitted from the default start.
****************************************************************************
capture program drop pr_cde_weights
program define pr_cde_weights, rclass
syntax, cancertype(string) [bootweight(varname) savestart usestart]

	* Sort only if needed (pr_cde_km restores this order, so normally a no-op)
	local sorted_by : sortedby
	if "`sorted_by'" != "e_patid record_id interval_number" sort e_patid record_id interval_number
	foreach v in probability_exposed weight_exposure probability_death log_prob_alive ///
		cumulative_log_alive n_missing_before weight_death weight_final {
		capture drop `v'
	}

	if "`bootweight'" == "" {
		tempvar one
		quietly gen byte `one' = 1
		local bootweight `one'
	}
	local fw     "[fweight = `bootweight']"
	local inboot "`bootweight' > 0"

	* ---- A: exposure model (first record of each spell) -------------------
	local from_exp
	if "`usestart'" != "" {
		capture confirm matrix cde_start_exp
		if !_rc local from_exp "from(cde_start_exp, skip)"
	}
	capture noisily logit exposed $baseline_confounders if interval_number == 1 & `inboot' `fw', `from_exp'
	local rc = _rc
	if `rc' & "`from_exp'" != "" {
		noisily display as error "Exposure model failed from start values - refitting from default start"
		logit exposed $baseline_confounders if interval_number == 1 & `inboot' `fw'
	}
	else if `rc' exit `rc'
	if "`savestart'" != "" matrix cde_start_exp = e(b)
	if e(N_cdf) + e(N_cds) > 0 noisily display as error "WARNING: exposure model has completely determined observations (a covariate level is all exposed or all unexposed)"
	* 'rules': rows covered by a perfect-prediction rule get 0/1, not missing
	quietly predict double probability_exposed, pr rules
	* Target population ($cde_estimand):
	*   ATT (default): the cancer survivors. Exposed weight 1; comparators
	*     weighted p/(1-p) to the survivors' confounder mix.
	*   ATE: the combined sample (about 91% comparators with 1:10 matching).
	*     Weights 1/p and 1/(1-p).
	if "$cde_estimand" == "ATT" {
		quietly gen double weight_exposure = cond(exposed == 1, 1, probability_exposed / (1 - probability_exposed))
	}
	else if "$cde_estimand" == "ATE" {
		quietly gen double weight_exposure = cond(exposed == 1, 1 / probability_exposed, 1 / (1 - probability_exposed))
	}
	else {
		display as error "cde_estimand must be ATT or ATE (currently: $cde_estimand)"
		exit 198
	}

	* ---- B: death models (discrete-time, one row per interval) -------------
	* Age enters as a restricted cubic spline ($cde_age_knots knots), with
	* its linear part varying by period and, in the exposed, by stage
	* ($cde_age_stage_int), so the weights can follow the steep, stage-
	* dependent age gradient in early cancer mortality
	* Separate models by exposure group. In the exposed group, optionally a
	* separate model for year 1 and for later follow-up, so every predictor's
	* association with death can differ between the period of highest early
	* mortality and longer-term survivorship. Age effect also varies by
	* period (<6m, 6m-2y, 2y+). Stage is included for the exposed group where
	* available.
	local stage_ok = (strpos(" $cde_nostage ", " `cancertype' ") == 0)
	capture confirm variable stage_tnm
	if _rc local stage_ok = 0

	* Link for the death models ($cde_death_link):
	*   cloglog (default): discrete-time proportional hazards (grouped-time Cox)
	*     model with an offset for the interval width (nominal width for
	*     complete intervals and deaths, time observed for records ending
	*     alive part-way through). Handles quarterly and annual intervals;
	*     all records are used.
	*   logit: pooled logistic; an indicator for quarterly vs annual intervals;
	*     censored partial final intervals excluded from fitting.
	* On pancreas, cloglog gave better covariate balance in year 1, when
	* per-quarter mortality is very high and the two links differ most.
	if "$cde_death_link" == "cloglog" {
		local death_cmd    "cloglog"
		local fit_rows     "1"
		local width_terms
		local death_opts   "offset(ln_width)"
		local predict_opts "pr"
	}
	else if "$cde_death_link" == "logit" {
		local death_cmd    "logit"
		local fit_rows     "death_model_row"
		local width_terms  "i.fine_interval"
		local death_opts
		local predict_opts "pr rules"
	}
	else {
		display as error "cde_death_link must be cloglog or logit (currently: $cde_death_link)"
		exit 198
	}

	* Non-linear age terms (spline from pr_cde_dataprep_grid; age_rcs1 = age,
	* which is already among the baseline confounders)
	local age_nl_terms
	if $cde_age_knots > 0 {
		capture unab age_nl_terms : age_rcs*
		local age_linear_term age_rcs1
		local age_nl_terms : list age_nl_terms - age_linear_term
	}

	quietly gen double probability_death = .
	forvalues group = 0/1 {
		local stage_terms
		local age_stage_terms
		if `group' == 1 & `stage_ok' local stage_terms "i.stage_tnm"
		* Age effect on death allowed to differ by stage (exposed only): older
		* women with advanced ovarian cancer, say, die much faster than the
		* main effects of age and stage alone imply
		if `group' == 1 & `stage_ok' & $cde_age_stage_int == 1 local age_stage_terms "c.age_c#i.stage_tnm"

		if `group' == 1 & $cde_split_exposed_death == 1 local fit_conditions `""time_mid < 1" "time_mid >= 1""'
		else local fit_conditions `""1""'

		local condition_number = 0
		foreach condition of local fit_conditions {
			local ++condition_number
			local start_matrix "cde_start_d`group'_`condition_number'"
			display as text _n "Death model (`death_cmd'): exposed==`group', records with (`condition')"

			local from_d
			if "`usestart'" != "" {
				capture confirm matrix `start_matrix'
				if !_rc local from_d "from(`start_matrix', skip)"
			}

			local full_terms    "$baseline_confounders `age_nl_terms' $time_varying_death_predictors `stage_terms' time_rcs* `width_terms' c.age_c#i.death_period `age_stage_terms'"
			* Fallback model: drops the age interactions (with period and stage)
			local reduced_terms "$baseline_confounders `age_nl_terms' $time_varying_death_predictors `stage_terms' time_rcs* `width_terms'"
			local fit_if        "if exposed == `group' & `fit_rows' & (`condition') & `inboot'"

			* The log-likelihood (logit or cloglog) is concave, so every start
			* that converges gives the same estimates; the attempts below differ
			* only in where the maximisation starts.

			* Attempt 1: saved start values (bootstrap replicates) or Stata's default
			capture noisily `death_cmd' died_this_interval `full_terms' `fit_if' `fw', `death_opts' iterate(100) `from_d'
			local fit_failed = (_rc != 0)
			if !`fit_failed' local fit_failed = (e(converged) != 1)

			* Attempt 2: Stata's default start, if attempt 1 used saved values
			if `fit_failed' & "`from_d'" != "" {
				noisily display as error "Death model (exposed==`group', `condition') failed from saved start values - refitting from default start"
				capture noisily `death_cmd' died_this_interval `full_terms' `fit_if' `fw', `death_opts' iterate(100)
				local fit_failed = (_rc != 0)
				if !`fit_failed' local fit_failed = (e(converged) != 1)
			}

			* Attempt 3: start from the constant-only model (all slopes zero).
			* Stata's default start can give impossible probabilities for some
			* records ("initial values not feasible", r(1400)), e.g. when the
			* spline terms take large values over the fitted time range; a
			* constant-only start is always feasible.
			if `fit_failed' {
				noisily display as error "Death model (exposed==`group', `condition') failed - refitting from constant-only start values"
				capture `death_cmd' died_this_interval `fit_if' `fw', `death_opts'
				if !_rc {
					matrix cde_null_start = e(b)
					capture noisily `death_cmd' died_this_interval `full_terms' `fit_if' `fw', `death_opts' iterate(100) from(cde_null_start, skip)
					local fit_failed = (_rc != 0)
					if !`fit_failed' local fit_failed = (e(converged) != 1)
				}
			}

			* Fallback: refit without the age x period terms rather than stopping
			* (constant-only start if available); an error here stops the run
			if `fit_failed' {
				noisily display as error "Death model (exposed==`group', `condition') did not converge - refitting without age x period (and age x stage) terms"
				local from_null
				capture confirm matrix cde_null_start
				if !_rc local from_null "from(cde_null_start, skip)"
				`death_cmd' died_this_interval `reduced_terms' `fit_if' `fw', `death_opts' `from_null'
			}
			capture matrix drop cde_null_start
			if "`savestart'" != "" matrix `start_matrix' = e(b)
			* (only logit stores these; missing > 0 is true in Stata, hence the guard)
			if !missing(e(N_cdf)) & !missing(e(N_cds)) {
				if e(N_cdf) + e(N_cds) > 0 noisily display as text "Note: death model (exposed==`group', `condition') has " ///
					e(N_cdf) + e(N_cds) " completely determined obs (sparse category) - handled with predict, rules"
			}

			* Predicted for every record in the subset (not only fitting rows);
			* with cloglog, includes the offset, i.e. P(death within the record's
			* own width) - complete intervals are the ones whose weights matter
			quietly predict double temporary_probability if exposed == `group' & (`condition'), `predict_opts'
			quietly replace probability_death = temporary_probability if exposed == `group' & (`condition')
			drop temporary_probability
		}
	}

	* ---- C: death weight at the START of each interval ---------------------
	* = 1 / product of P(alive) over all PREVIOUS intervals of the spell
	quietly gen double log_prob_alive = ln(1 - probability_death)
	quietly by e_patid record_id: gen double cumulative_log_alive = sum(log_prob_alive) - cond(missing(log_prob_alive), 0, log_prob_alive)
	quietly by e_patid record_id: gen int n_missing_before = sum(missing(log_prob_alive)) - missing(log_prob_alive)
	quietly gen double weight_death = cond(n_missing_before == 0, exp(-cumulative_log_alive), .)

	* ---- D: switches, combined weight, optional truncation -----------------
	if $CDEKMexposureweightson == 0 quietly replace weight_exposure = 1
	if $CDEKMdeathweightson    == 0 quietly replace weight_death    = 1
	quietly gen double weight_final = weight_exposure * weight_death

	if $cde_truncation_pct < 100 {
		foreach w in weight_final weight_death {
			quietly summarize `w' if `inboot' `fw', detail
			local cut = r(p$cde_truncation_pct)
			* !missing(): in Stata missing > any number
			quietly replace `w' = `cut' if `w' > `cut' & !missing(`w')
		}
	}

	quietly count if missing(weight_final) & `inboot'
	if r(N) > 0 noisily display as error "WARNING: " r(N) " records have a missing weight (missing covariate in a weight model?) and will be excluded"

	quietly summarize weight_final if `inboot' `fw', detail
	return scalar weight_final_mean = r(mean)
	return scalar weight_final_p99  = r(p99)
	return scalar weight_final_max  = r(max)
	quietly summarize weight_death if `inboot' `fw', detail
	return scalar weight_death_mean = r(mean)
	return scalar weight_death_p99  = r(p99)
	return scalar weight_death_max  = r(max)

end


****************************************************************************
* pr_cde_km
*   Weighted KM (weight_final x bootstrap frequency), each record its own
*   left-truncated subject. Returns, for each horizon h (years), with
*   m = h x 12 (months, used in the names because "." is not allowed):
*     r(risk1_m) r(risk0_m) r(rr_m) r(rd_m)
*   Leaves km_survival (and the stset) in the data for the curve.
*   sortpreserve: the sort order is restored on exit, so pr_cde_weights does
*   not have to re-sort the whole dataset in the next bootstrap replicate.
****************************************************************************
capture program drop pr_cde_km
program define pr_cde_km, rclass sortpreserve
syntax, horizons(numlist) [bootweight(varname)]

	capture stset, clear
	foreach v in _st _d _t _t0 km_pweight km_survival {
		capture drop `v'
	}

	if "`bootweight'" == "" {
		tempvar one
		quietly gen byte `one' = 1
		local bootweight `one'
	}

	quietly gen double km_pweight = weight_final * `bootweight'
	quietly stset tstop if `bootweight' > 0 & !missing(km_pweight) [pweight = km_pweight], failure(event) enter(time tstart)
	quietly sts generate km_survival = s, by(exposed)

	* KM is a non-increasing step function, so min(S) over records with _t <= h is S(h)
	foreach h of local horizons {
		local m = round(`h' * 12)
		forvalues g = 0/1 {
			quietly summarize km_survival if _st == 1 & exposed == `g' & _t <= `h', meanonly
			local risk`g' = 1 - r(min)
		}
		return scalar risk1_`m' = `risk1'
		return scalar risk0_`m' = `risk0'
		return scalar rr_`m'    = cond(`risk0' > 0 & !missing(`risk0'), `risk1' / `risk0', .)
		return scalar rd_`m'    = `risk1' - `risk0'
	}
	return local horizons "`horizons'"

end


****************************************************************************
* pr_cde_cif
*   Total effect: exposure-weighted Aalen-Johansen cumulative incidence of
*   dementia diagnosis, with death as a competing event (no death weights).
*   Same records, exposure weights and bootstrap frequencies as the CDE KM,
*   so the two estimands differ only in how death is handled.
*   At each event time t_j (dementia or death), by exposure group:
*     CIF(t) = sum over t_j <= t of [S(t_j-) - S(t_j)] x d_dem(t_j) / d_all(t_j)
*   where S is the weighted KM for the first of dementia or death, and d are
*   weighted numbers of events (i.e. S(t_j-) x d_dem(t_j) / Y(t_j)).
*   Returns, for each horizon h (m = h x 12):
*     r(trisk1_m) r(trisk0_m) r(trr_m) r(trd_m)
*   keepcurve: leaves the curve in frame cde_cif_curve (exposed time_years
*   cif_dementia cif_death s_all) for the analysis file to save.
*   sortpreserve: the data's sort order is unchanged on exit.
****************************************************************************
capture program drop pr_cde_cif
program define pr_cde_cif, rclass sortpreserve
syntax, horizons(numlist) [bootweight(varname) keepcurve]

	capture stset, clear
	foreach v in _st _d _t _t0 cif_pweight cif_s_all cif_any_event {
		capture drop `v'
	}

	if "`bootweight'" == "" {
		tempvar one
		quietly gen byte `one' = 1
		local bootweight `one'
	}

	* First event of either type (mutually exclusive by construction:
	* died_this_spell is only set when the spell did not end in dementia)
	quietly gen byte   cif_any_event = (event == 1 | died_this_interval == 1)
	quietly gen double cif_pweight   = weight_exposure * `bootweight'
	quietly stset tstop if `bootweight' > 0 & !missing(cif_pweight) [pweight = cif_pweight], ///
		failure(cif_any_event) enter(time tstart)
	quietly sts generate cif_s_all = s, by(exposed)

	* Event times only, in a separate frame (avoids copying the whole data)
	capture frame drop cde_cif_work
	frame put exposed _t cif_s_all cif_pweight event if _st == 1 & _d == 1, into(cde_cif_work)
	frame cde_cif_work {
		quietly gen double w_dem = cif_pweight * (event == 1)
		quietly collapse (min) s_all = cif_s_all (sum) w_dem w_all = cif_pweight, by(exposed _t)
		rename _t time_years
		sort exposed time_years
		quietly by exposed: gen double s_prev = cond(_n == 1, 1, s_all[_n - 1])
		quietly gen double cif_dementia = (s_prev - s_all) * w_dem / w_all
		quietly gen double cif_death    = (s_prev - s_all) * (1 - w_dem / w_all)
		quietly by exposed: replace cif_dementia = sum(cif_dementia)
		quietly by exposed: replace cif_death    = sum(cif_death)
	}

	foreach h of local horizons {
		local m = round(`h' * 12)
		forvalues g = 0/1 {
			frame cde_cif_work: quietly summarize cif_dementia if exposed == `g' & time_years <= `h', meanonly
			local risk`g' = cond(r(N) > 0, r(max), 0)
		}
		return scalar trisk1_`m' = `risk1'
		return scalar trisk0_`m' = `risk0'
		return scalar trr_`m'    = cond(`risk0' > 0 & !missing(`risk0'), `risk1' / `risk0', .)
		return scalar trd_`m'    = `risk1' - `risk0'
	}

	capture frame drop cde_cif_curve
	if "`keepcurve'" != "" frame rename cde_cif_work cde_cif_curve
	else frame drop cde_cif_work

	capture stset, clear
	foreach v in _st _d _t _t0 cif_pweight cif_s_all cif_any_event {
		capture drop `v'
	}

end


****************************************************************************
* pr_cde_balance
*   Weighted covariate balance among those still at risk at each time t in
*   times(): mean of each variable by exposure group, unweighted and
*   weighted, and the weighted standardised mean difference (SMD), using
*   the pooled unweighted SD at baseline. Categorical variables are split
*   into one indicator per level. stagevar() (exposed only): the weighted
*   stage mix at t is compared with the weighted stage mix at baseline,
*   since the death weights should restore it. potfu(): potential follow-up
*   (years); if given, that baseline mix is taken over the exposed whose
*   potential follow-up reaches t, so that administrative censoring by
*   calendar time does not show up as imbalance.
*   (Exposed vs comparator SMDs need no such adjustment: matched sets share
*   an index date, so administrative censoring affects both groups alike.)
*   Prints a table per time; returns matrix r(balance) with columns
*   time, maxsmd (max |SMD| at that time, missing if a group is empty),
*   n_unexp, n_exp (unweighted numbers of records at risk), agediff.
*   agevar(): this variable (age) is judged separately, on the weighted
*   difference in years (exposed minus unexposed, column agediff), and is
*   left out of maxsmd; the caller compares |agediff| with agetol()
*   (default 0.5 years).
****************************************************************************
capture program drop pr_cde_balance
program define pr_cde_balance, rclass
syntax [varlist(default=none numeric)], times(numlist) [categorical(varlist numeric) stagevar(varname numeric) wvar(varname) potfu(varname numeric) agevar(varname numeric) agetol(real 0.5)]

	if "`wvar'" == "" local wvar weight_final

	* ---- balance variables: as given, plus one indicator per category level
	local balvars   `varlist'
	local ballabels `varlist'
	foreach c of local categorical {
		quietly levelsof `c', local(levels)
		foreach l of local levels {
			tempvar ind
			quietly gen byte `ind' = (`c' == `l') if !missing(`c')
			local balvars   `balvars' `ind'
			local ballabels `ballabels' `c'=`l'
		}
	}
	local k : word count `balvars'

	* ---- pooled unweighted baseline SD (first record of each spell)
	quietly tabstat `balvars' if interval_number == 1, by(exposed) statistics(variance) save
	if "`r(name1)'" != "0" {
		display as error "pr_cde_balance: expected exposed==0 as the first group"
		exit 459
	}
	matrix _bal_var0 = r(Stat1)
	matrix _bal_var1 = r(Stat2)

	* ---- stage indicators (exposed only) and their weighted baseline mix
	local s = 0
	if "`stagevar'" != "" {
		local stagevars
		local stagelabels
		quietly levelsof `stagevar' if exposed == 1, local(slevels)
		foreach l of local slevels {
			tempvar sind
			quietly gen byte `sind' = (`stagevar' == `l') if !missing(`stagevar')
			local stagevars   `stagevars' `sind'
			local stagelabels `stagelabels' `stagevar'=`l'
		}
		local s : word count `stagevars'
		* Baseline mix over ALL exposed (used when potfu() is not given;
		* otherwise recomputed at each t below)
		quietly tabstat `stagevars' if exposed == 1 & interval_number == 1 [aweight = `wvar'], statistics(mean) save
		matrix _bal_s0 = r(StatTotal)
	}

	* ---- weighted numbers at baseline, for the weighted-N check at each t
	quietly summarize `wvar' if interval_number == 1 & exposed == 0, meanonly
	local wn0_base = r(sum)
	quietly summarize `wvar' if interval_number == 1 & exposed == 1, meanonly
	local wn1_base = r(sum)

	* ---- one table per time
	local ntimes : word count `times'
	matrix _bal = J(`ntimes', 5, .)
	matrix colnames _bal = time maxsmd n_unexp n_exp agediff
	local row = 0
	foreach t of local times {
		local ++row
		tempvar atrisk
		quietly gen byte `atrisk' = (tstart <= `t' & tstop > `t')
		quietly count if `atrisk' & exposed == 0
		local n0 = r(N)
		quietly count if `atrisk' & exposed == 1
		local n1 = r(N)
		matrix _bal[`row', 1] = `t'
		matrix _bal[`row', 3] = `n0'
		matrix _bal[`row', 4] = `n1'

		display as text _n "{hline 92}"
		display as text "Balance among those at risk at t = " %5.2f `t' " years   (records at risk: unexposed " `n0' ", exposed " `n1' ")"
		if `n0' == 0 | `n1' == 0 {
			display as error "  One group has no-one at risk: balance not assessable"
			drop `atrisk'
			continue
		}

		quietly tabstat `balvars' if `atrisk', by(exposed) statistics(mean) save
		matrix _bal_u0 = r(Stat1)
		matrix _bal_u1 = r(Stat2)
		quietly tabstat `balvars' if `atrisk' [aweight = `wvar'], by(exposed) statistics(mean) save
		matrix _bal_w0 = r(Stat1)
		matrix _bal_w1 = r(Stat2)

		* Weighted-N check: if the death weights work, the weighted number at
		* risk at t reproduces the baseline number, less those lost to exits
		* other than death (censoring, dementia), which the weights do not
		* replace. A figure well below 100% minus the share lost to non-death
		* exits by t means the death weights under-correct.
		quietly summarize `wvar' if `atrisk' & exposed == 0, meanonly
		local wn0 = r(sum)
		quietly summarize `wvar' if `atrisk' & exposed == 1, meanonly
		local wn1 = r(sum)
		display as text "  Weighted number at risk as % of baseline: unexposed " %5.1f 100 * `wn0' / `wn0_base' ///
			"%, exposed " %5.1f 100 * `wn1' / `wn1_base' "%"

		display as text %-26s "variable" %12s "unexp(unw)" %12s "exp(unw)" %12s "unexp(wtd)" %12s "exp(wtd)" %10s "SMD(wtd)"
		local maxsmd = 0
		local agediff = .
		forvalues j = 1/`k' {
			local lab : word `j' of `ballabels'
			local sd = sqrt((_bal_var0[1, `j'] + _bal_var1[1, `j']) / 2)
			local smd = .
			if `sd' > 0 & !missing(`sd') local smd = (_bal_w1[1, `j'] - _bal_w0[1, `j']) / `sd'
			* Age (agevar()): judged on the weighted difference in YEARS
			* (exposed minus unexposed) against agetol(), not on its SMD -
			* dementia risk rises so steeply with age that an SMD below 0.1
			* (about a year) can still bias the comparison
			if "`agevar'" != "" & "`lab'" == "`agevar'" {
				local agediff = _bal_w1[1, `j'] - _bal_w0[1, `j']
				display as result %-26s abbrev("`lab'", 26) %12.3f _bal_u0[1, `j'] %12.3f _bal_u1[1, `j'] ///
					%12.3f _bal_w0[1, `j'] %12.3f _bal_w1[1, `j'] %10.3f `smd' "  diff " %6.2f `agediff' " years" ///
					cond(abs(`agediff') > `agetol' & !missing(`agediff'), "  *", "")
				continue
			}
			if !missing(`smd') & abs(`smd') > `maxsmd' local maxsmd = abs(`smd')
			display as result %-26s abbrev("`lab'", 26) %12.3f _bal_u0[1, `j'] %12.3f _bal_u1[1, `j'] ///
				%12.3f _bal_w0[1, `j'] %12.3f _bal_w1[1, `j'] %10.3f `smd' cond(abs(`smd') >= $cde_smd_threshold & !missing(`smd'), "  *", "")
		}

		if `s' > 0 {
			* Baseline comparison group: exposed whose potential follow-up
			* reaches t (if potfu() given), so the comparison is not distorted
			* by calendar-time (administrative) censoring, e.g. more unknown
			* stage among those diagnosed in earlier years
			if "`potfu'" != "" {
				quietly count if exposed == 1 & interval_number == 1 & `potfu' >= `t'
				if r(N) > 0 {
					quietly tabstat `stagevars' if exposed == 1 & interval_number == 1 & `potfu' >= `t' [aweight = `wvar'], statistics(mean) save
					matrix _bal_s0 = r(StatTotal)
				}
				else matrix _bal_s0 = J(1, `s', .)
			}
			quietly tabstat `stagevars' if `atrisk' & exposed == 1 [aweight = `wvar'], statistics(mean) save
			matrix _bal_st = r(StatTotal)
			if "`potfu'" != "" display as text _n "  Exposed only: weighted stage mix at t vs at baseline (exposed with potential follow-up >= t)"
			else display as text _n "  Exposed only: weighted stage mix at t vs at baseline"
			display as text %-26s "stage" %12s "baseline" %12s "at t" %10s "SMD"
			forvalues j = 1/`s' {
				local lab : word `j' of `stagelabels'
				local p0 = _bal_s0[1, `j']
				local smd = .
				if `p0' > 0 & `p0' < 1 & !missing(`p0') local smd = (_bal_st[1, `j'] - `p0') / sqrt(`p0' * (1 - `p0'))
				if !missing(`smd') & abs(`smd') > `maxsmd' local maxsmd = abs(`smd')
				display as result %-26s abbrev("`lab'", 26) %12.3f `p0' %12.3f _bal_st[1, `j'] %10.3f `smd' ///
					cond(abs(`smd') >= $cde_smd_threshold & !missing(`smd'), "  *", "")
			}
		}

		matrix _bal[`row', 2] = `maxsmd'
		matrix _bal[`row', 5] = `agediff'
		if "`agevar'" != "" {
			display as text "  Max |SMD| at t = " %5.2f `t' " (excluding `agevar'): " %6.3f `maxsmd' "   (* = at or above $cde_smd_threshold)"
			display as text "  Weighted `agevar' difference (exposed - unexposed): " %6.2f `agediff' " years   (* = beyond +/-" %4.2f `agetol' ")"
		}
		else display as text "  Max |SMD| at t = " %5.2f `t' ": " %6.3f `maxsmd' "   (* = at or above $cde_smd_threshold)"
		drop `atrisk'
	}

	return matrix balance = _bal
	capture matrix drop _bal_var0 _bal_var1 _bal_u0 _bal_u1 _bal_w0 _bal_w1 _bal_s0 _bal_st

end
