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
	local cluster = "statefips"
	local absorb  = "year_month"
	
	local exp_ln_mw_var "exp_ln_mw_17"
	
	** STATIC
	use "`instub'/baseline_zipcode_months.dta", clear
	xtset zipcode_num `absorb'

	estimate_dist_lag_model if !missing(D.ln_rents), depvar(`exp_ln_mw_var') ///
		dyn_var(ln_mw) w(0) stat_var(ln_mw) ///
		controls(`controls') absorb(`absorb') cluster(`cluster') ///
		model_name(exp_mw_on_mw) outfolder("../temp")

	estimate_dist_lag_model, depvar(ln_rents) ///
		dyn_var(ln_mw) w(0) stat_var(ln_mw) ///
		controls(`controls') absorb(`absorb') cluster(`cluster') ///
		model_name(static_statutory) outfolder("../temp")

	estimate_dist_lag_model, depvar(ln_rents) ///
		dyn_var(`exp_ln_mw_var') w(0) stat_var(`exp_ln_mw_var') ///
		controls(`controls') absorb(`absorb') cluster(`cluster') ///
		model_name(static_experienced) outfolder("../temp")

	estimate_dist_lag_model, depvar(ln_rents) ///
		dyn_var(`exp_ln_mw_var') w(0) stat_var(ln_mw) ///
		controls(`controls') absorb(`absorb') cluster(`cluster') ///
		model_name(static_both) test_equality outfolder("../temp")

	use ../temp/estimates_exp_mw_on_mw.dta, clear
	gen p_equality = .
	foreach ff in static_statutory static_experienced static_both {
		append using ../temp/estimates_`ff'.dta
	}
	save             `outstub'/estimates_static.dta, replace
	export delimited `outstub'/estimates_static.csv, replace
	
	** DYNAMIC
	use "`instub'/baseline_zipcode_months.dta", clear
	xtset zipcode_num `absorb'

    estimate_dist_lag_model, depvar(ln_rents) ///
	    dyn_var(`exp_ln_mw_var') w(6) stat_var(ln_mw) ///
		controls(`controls') absorb(`absorb') cluster(`cluster') ///
		model_name(baseline_`exp_ln_mw_var'_dynamic) outfolder("../temp")
		
    estimate_dist_lag_model, depvar(ln_rents) ///
	    dyn_var(ln_mw) w(6) stat_var(`exp_ln_mw_var') ///
		controls(`controls') absorb(`absorb') cluster(`cluster') ///
		model_name(both_ln_mw_dynamic) outfolder("../temp")
		
    estimate_dist_lag_model, depvar(ln_rents) ///
	    dyn_var(`exp_ln_mw_var') w(6) stat_var(`exp_ln_mw_var') ///
		controls(`controls') absorb(`absorb') cluster(`cluster') ///
		model_name(`exp_ln_mw_var'_only_dynamic) outfolder("../temp")
		
    estimate_dist_lag_model, depvar(ln_rents) ///
	    dyn_var(ln_mw) w(6) stat_var(ln_mw) ///
		controls(`controls') absorb(`absorb') cluster(`cluster') ///
		model_name(ln_mw_only_dynamic) outfolder("../temp")
		
    estimate_dist_lag_model_two_dyn, depvar(ln_rents) ///
	    dyn_var1(`exp_ln_mw_var') w(6) dyn_var2(ln_mw) ///
		controls(`controls') absorb(`absorb') cluster(`cluster') ///
		model_name(both_dynamic) outfolder("../temp")
		
	use ../temp/estimates_baseline_`exp_ln_mw_var'_dynamic.dta, clear
	foreach ff in both_ln_mw_dynamic `exp_ln_mw_var'_only_dynamic ///
	    ln_mw_only_dynamic both_dynamic {
		append using ../temp/estimates_`ff'.dta
	}
	save             `outstub'/estimates_dynamic.dta, replace
	export delimited `outstub'/estimates_dynamic.csv, replace
end

main
