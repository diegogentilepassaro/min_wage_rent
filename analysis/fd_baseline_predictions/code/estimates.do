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
	
	use "`instub'/baseline_zipcode_months.dta", clear
	xtset zipcode_num `absorb'

	gen d_ln_rents = ln_rents[_n] - ln_rents[_n-1]
	gen d_ln_mw = ln_mw[_n] - ln_mw[_n-1]
	gen d_`exp_ln_mw_var' = `exp_ln_mw_var'[_n] - `exp_ln_mw_var'[_n-1]
	
 	reghdfe d_ln_rents d_`exp_ln_mw_var' d_ln_mw ///
	    `controls', absorb(`absorb', savefe) ///
	    vce(cluster `cluster') nocons residuals(residuals)
	
    predict p_d_ln_rents if e(sample) == 1, xbd
	
	keep zipcode year_month ln_rents p_d_ln_rents residuals
	save_data "../output/baseline_model_predictions.dta", ///
	    key(zipcode year_month) replace
end

main
