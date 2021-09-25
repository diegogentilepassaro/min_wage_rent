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
	
	local cluster "statefips"
	local absorb year_month#statefips_num
	
	** STATIC
	use "`instub'/baseline_county_months.dta", clear
	xtset county_num year_month

	estimate_dist_lag_model if !missing(D.ln_med_rent_var), depvar(exp_ln_mw) ///
		dyn_var(ln_mw) w(0) stat_var(ln_mw) ///
		controls(`controls') absorb(`absorb') cluster(`cluster') ///
		model_name(exp_mw_on_mw) outfolder("../temp")

	estimate_dist_lag_model, depvar(ln_med_rent_var) ///
		dyn_var(ln_mw) w(0) stat_var(ln_mw) ///
		controls(`controls') absorb(`absorb') cluster(`cluster') ///
		model_name(static_statutory) outfolder("../temp")

	estimate_dist_lag_model, depvar(ln_med_rent_var) ///
		dyn_var(exp_ln_mw) w(0) stat_var(exp_ln_mw) ///
		controls(`controls') absorb(`absorb') cluster(`cluster') ///
		model_name(static_experienced) outfolder("../temp")

	estimate_dist_lag_model, depvar(ln_med_rent_var) ///
		dyn_var(exp_ln_mw) w(0) stat_var(ln_mw) ///
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
	use "`instub'/baseline_county_months.dta", clear
	xtset county_num year_month

    estimate_dist_lag_model, depvar(ln_med_rent_var) ///
	    dyn_var(exp_ln_mw) w(6) stat_var(ln_mw) ///
		controls(`controls') absorb(`absorb') cluster(`cluster') ///
		model_name(baseline_exp_ln_mw_dynamic) outfolder("../temp")
		
    estimate_dist_lag_model, depvar(ln_med_rent_var) ///
	    dyn_var(ln_mw) w(6) stat_var(exp_ln_mw) ///
		controls(`controls') absorb(`absorb') cluster(`cluster') ///
		model_name(both_ln_mw_dynamic) outfolder("../temp")
		
    estimate_dist_lag_model, depvar(ln_med_rent_var) ///
	    dyn_var(exp_ln_mw) w(6) stat_var(exp_ln_mw) ///
		controls(`controls') absorb(`absorb') cluster(`cluster') ///
		model_name(exp_ln_mw_only_dynamic) outfolder("../temp")
		
    estimate_dist_lag_model, depvar(ln_med_rent_var) ///
	    dyn_var(ln_mw) w(6) stat_var(ln_mw) ///
		controls(`controls') absorb(`absorb') cluster(`cluster') ///
		model_name(ln_mw_only_dynamic) outfolder("../temp")
		
	use ../temp/estimates_baseline_exp_ln_mw_dynamic.dta, clear
	foreach ff in both_ln_mw_dynamic exp_ln_mw_only_dynamic ln_mw_only_dynamic {
		append using ../temp/estimates_`ff'.dta
	}
	save             `outstub'/estimates_dynamic.dta, replace
	export delimited `outstub'/estimates_dynamic.csv, replace
end

main