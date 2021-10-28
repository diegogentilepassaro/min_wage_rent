clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../../../drive/derived_large/estimation_samples"
	local in_cf_mw    "../../../drive/derived_large/min_wage"
	
	define_controls
	local controls "`r(economic_controls)'"
	local cluster = "statefips"
	local absorb  = "year_month"
	
    process_counterfactual_data, in_cf_mw(`in_cf_mw') ///
	    instub(`instub') controls(`controls')
	
	local exp_ln_mw_var "exp_ln_mw_17"
	
	use zipcode zipcode_num statefips year_month year month ///
	    ln_rents ln_mw `exp_ln_mw_var' `controls' ///
		using "`instub'/baseline_zipcode_months.dta", clear
	xtset zipcode_num `absorb'

	gen d_ln_rents = ln_rents[_n] - ln_rents[_n-1]
	gen d_ln_mw = ln_mw[_n] - ln_mw[_n-1]
	gen d_`exp_ln_mw_var' = `exp_ln_mw_var'[_n] - `exp_ln_mw_var'[_n-1]
	
 	reghdfe d_ln_rents d_`exp_ln_mw_var' d_ln_mw ///
	    `controls', absorb(`absorb', savefe) ///
	    vce(cluster `cluster') nocons residuals(residuals)
	keep if e(sample)
	append using "../temp/counterfactual_fed_9usd.dta"
    predict p_d_ln_rents if year == 2020, xb
	
	keep zipcode year month ln_rents p_d_ln_rents residuals __hdfe1__
	save_data "../output/fd_baseline_predictions.dta", ///
	    key(zipcode year month) replace
end

program process_counterfactual_data
    syntax, in_cf_mw(str) instub(str) controls(str)
	
	use zipcode year month counterfactual exp_ln_mw_tot using ///
	    "`in_cf_mw'/zipcode_experienced_mw_cfs.dta", clear
    keep if (year == 2020 & month == 1)
	rename exp_ln_mw_tot exp_ln_mw_tot_18_cf
	gen fed_mw_cf = 7.25*1.1 if counterfactual == "fed_10pc"
	replace fed_mw_cf = 15 if counterfactual == "fed_15usd"
	replace fed_mw_cf = 9 if counterfactual == "fed_9usd"
	save "../temp/counterfactual.dta", replace
	
	use "`instub'/baseline_zipcode_months.dta", clear
    xtset zipcode_num `absorb'
	keep if (year == 2019 & month == 12)
	keep zipcode ln_mw exp_ln_mw_17 `controls'
	expand 3
	bysort zipcode: gen counterfactual = "fed_10pc" if _n == 1
	bysort zipcode: replace counterfactual = "fed_15usd" if _n == 2
	bysort zipcode: replace counterfactual = "fed_9usd" if _n == 3
	merge 1:1 zipcode counterfactual using "../temp/counterfactual.dta", ///
		nogen keep(3)
	gen d_ln_mw = ln_mw - log(fed_mw_cf)
	gen d_exp_ln_mw_17 = exp_ln_mw_tot_18_cf - exp_ln_mw_17
	drop fed_mw_cf exp_ln_mw_tot_18_cf ln_mw exp_ln_mw_17
	preserve
	    keep if counterfactual == "fed_10pc"
		drop counterfactual
		save "../temp/counterfactual_fed_10pc.dta", replace
	restore
	preserve
	    keep if counterfactual == "fed_15usd"
		drop counterfactual
		save "../temp/counterfactual_fed_15usd.dta", replace
	restore
	preserve
	    keep if counterfactual == "fed_9usd"
		drop counterfactual
		save "../temp/counterfactual_fed_9usd.dta", replace
	restore
end

main
