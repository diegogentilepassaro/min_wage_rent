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
		model_name(baseline_static)
		
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

program estimate_dist_lag_model 
	syntax [if], depvar(str) dyn_var(str) stat_var(str) ///
	    controls(str) absorb(str) cluster(str) model_name(str) [w(int 6)]

	preserve
		reghdfe D.`depvar' L(-`w'/`w').D.`dyn_var' D.`stat_var' D.(`controls'), ///
			absorb(`absorb') vce(cluster `cluster') nocons
		estimate save "../temp/estimates.dta", replace
		
		coefplot, vertical base gen
		keep __at __b __se
		rename (__at __b __se) (at b se)

		local winspan = 2*`w' + 1
		keep if _n <= `winspan' + 1
		keep if !missing(at)
		
		gen model = "`model_name'"
		gen var = "`dyn_var'" if _n <= `winspan'
		replace var = "`stat_var'" if _n == `winspan' + 1
		replace at = at - (`w' + 1)
		replace at = 0 if _n == `winspan' + 1
		save "../temp/estimates_`model_name'.dta", replace
		
		estimate use "../temp/estimates.dta"
		if "`dyn_var'" == "`stat_var'" {
		    local sum_string "D.`stat_var'"
		}
		else {
		    local sum_string "D.`dyn_var' + D.`stat_var'"  
		}
		lincom `sum_string'
		matrix cumsum = (0, r(estimate), r(se))
		if `w' > 0 {
			forval t = 1(1)`w'{
				estimate use "../temp/estimates.dta"
				local sum_string "`sum_string' + L`w'.D.`dyn_var'"
				lincom `sum_string'
			matrix cumsum = (matrix(cumsum) \ `t', r(estimate), r(se))
			mat list cumsum
			}
		}
		clear
		svmat cumsum
		rename (cumsum1 cumsum2 cumsum3) ///
			(at b se)
		gen model = "`model_name'"
		gen var = "cumsum_from0"
		save "../temp/estimates_`model_name'_sumsum_from0.dta", replace

		use "../temp/estimates_`model_name'.dta", clear
		append using "../temp/estimates_`model_name'_sumsum_from0.dta"
		save "../output/estimates_`model_name'.dta", replace
		export delimited "../output/estimates_`model_name'.csv", replace
	restore
end 

main
