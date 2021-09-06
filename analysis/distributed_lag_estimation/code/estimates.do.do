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
	    dyn_var(exp_ln_mw) w(6) stat_var(ln_mw) ///
		controls(`controls') absorb(year_month) cluster(cbsa10) ///
		model_name(baseline)
	

    /* test (D.ln_mw = D.exp_ln_mw)
	eststo: reghdfe D.exp_ln_mw D.ln_mw D.(`controls') if !missing(D.ln_med_rent_var), ///
		absorb(`absorb') vce(cluster `cluster') nocons*/

end

program estimate_dist_lag_model 
	syntax [if], depvar(str) dyn_var(str) stat_var(str) ///
	    controls(str) absorb(str) cluster(str) model_name(str) [w(int 6)]

	reghdfe D.`depvar' L(-`w'/`w').D.`dyn_var' D.`stat_var' D.(`controls'), ///
		absorb(`absorb') vce(cluster `cluster') nocons
	preserve
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
	restore
	
	/*qui reghdfe D.`depvar' D.ln_mw D.exp_ln_mw D.(`controls'), ///
		absorb(`absorb') vce(cluster `cluster') nocons
	compute_cumsum, coefficients(D.ln_mw + D.exp_ln_mw)

	local cumsum_b "`r(cumsum_b)'"
	local cumsum_V "`r(cumsum_V)'"*/

end 

main