clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000

program main
    local instub      "../../../drive/derived_large/"
	local in_baseline "../../../drive/derived_large/estimation_samples"
	local in_cf_mw    "../../../drive/derived_large/min_wage"
	
	define_controls
	local controls "`r(economic_controls)'"
	local cluster = "statefips"
	local absorb  = "year#cbsa10_num"
	
    process_counterfactual_data, in_cf_mw(`in_cf_mw') ///
	    instub(`in_baseline') controls(`controls')
		
    use "`instub'/zipcode_year/zipcode_year.dta", clear
	reghdfe ln_wagebill exp_ln_mw_tot_18_avg i.zipcode_num , ///
        absorb(`absorb', savefe) vce(cluster `cluster') ///
		nocons residuals(residuals)
	append using "../temp/counterfactual_fed_9usd.dta"
	replace ln_mw_avg = ln_mw_cf if year == 2020
	replace exp_ln_mw_tot_18_avg = exp_ln_mw_tot_18_cf if year == 2020
    predict p_ln_wagebill if year == 2020, xb	
	keep zipcode year ln_wagebill p_ln_wagebill residuals
	save_data "../output/twfe_wages_predictions.dta", ///
	    key(zipcode year) replace
end

program process_counterfactual_data
    syntax, in_cf_mw(str) instub(str) controls(str)
	
	/*use zipcode year month counterfactual exp_ln_mw_tot using ///
	    "`in_cf_mw'/zipcode_experienced_mw_cfs.dta", clear*/
		
	use "zipcode_experienced_mw_cfs.dta", clear
	
    keep if (year == 2020 & month == 1)
	rename exp_ln_mw_tot exp_ln_mw_tot_18_cf
	gen fed_mw_cf = 7.25*1.1 if counterfactual == "fed_10pc"
	replace fed_mw_cf = 15 if counterfactual == "fed_15usd"
	replace fed_mw_cf = 9 if counterfactual == "fed_9usd"
	save "../temp/counterfactual.dta", replace
	
	use "`instub'/all_zipcode_months.dta", clear
	keep if (year == 2019 & month == 12)
	keep zipcode actual_mw
	expand 3
	bysort zipcode: gen counterfactual = "fed_10pc" if _n == 1
	bysort zipcode: replace counterfactual = "fed_15usd" if _n == 2
	bysort zipcode: replace counterfactual = "fed_9usd" if _n == 3
	merge 1:1 zipcode counterfactual using "../temp/counterfactual.dta", ///
		nogen keep(3)
	egen actual_mw_cf = rowmax(actual_mw fed_mw_cf)
	gen ln_mw_cf = log(actual_mw_cf)
	keep zipcode year exp_ln_mw_tot_18_cf ln_mw_cf counterfactual
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
