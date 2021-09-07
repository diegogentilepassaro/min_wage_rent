clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../../../drive/derived_large/estimation_samples"
	local outstub "../output"
	
	define_controls
	local controls "`r(economic_controls)'"
	di "`controls'"
	
	use "`instub'/baseline_zipcode_months.dta", clear
	xtset zipcode_num year_month
	
    estimate_dist_lag_model, depvar(ln_med_rent_var) ///
	    dyn_var(exp_ln_mw) w(0) stat_var(ln_mw) ///
		controls(`controls') absorb(year_month) cluster(cbsa10) ///
		model_name(baseline_static) test_equality
		
    estimate_dist_lag_model if !missing(D.ln_med_rent_var), depvar(exp_ln_mw) ///
	    dyn_var(ln_mw) w(0) stat_var(ln_mw) ///
		controls(`controls') absorb(year_month) cluster(cbsa10) ///
		model_name(exp_mw_is_not_mw)
	
    estimate_dist_lag_model, depvar(ln_med_rent_var) ///
	    dyn_var(exp_ln_mw) w(6) stat_var(ln_mw) ///
		controls(`controls') absorb(year_month) cluster(cbsa10) ///
		model_name(baseline_dynamic)
		
    estimate_dist_lag_model, depvar(ln_med_rent_var) ///
	    dyn_var(ln_mw) w(6) stat_var(exp_ln_mw) ///
		controls(`controls') absorb(year_month) cluster(cbsa10) ///
		model_name(ln_mw_dynamic)
end

main
