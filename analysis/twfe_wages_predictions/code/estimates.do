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
	local absorb  = "zipcode_num year#cbsa10_num"
	
    process_counterfactual_data, in_cf_mw(`in_cf_mw') ///
	    instub(`in_baseline') controls(`controls')
		
    use "`instub'/zipcode_year/zipcode_year.dta", clear
	keep if year < 2020
	reghdfe ln_wagebill exp_ln_mw_tot_18_avg, ///
        absorb(`absorb', savefe) vce(cluster `cluster') ///
		nocons residuals(residuals)
	append using "../temp/counterfactual_fed_9usd.dta"
	gen counterfactual = 0
	replace counterfactual = 1 if year == 2020 
	replace exp_ln_mw_tot_18_avg = exp_ln_mw_tot_18_avg_cf if year == 2020
	replace year = 2018 if year == 2020
	preserve 
	    collapse __hdfe1__, by(zipcode)
		save "../temp/zip_fes.dta", replace
	restore
	preserve 
	    collapse __hdfe2__, by(year cbsa10)
		save "../temp/time_fes.dta", replace
	restore
	drop __hdfe1__ __hdfe2__
	merge m:1 zipcode using "../temp/zip_fes.dta", nogen keep(1 3)
	merge m:1 year cbsa10 using "../temp/time_fes.dta", nogen keep(1 3)
    predict p_ln_wagebill, xb
    gen p_ln_wagebill_with_fe = p_ln_wagebill + __hdfe1__ + __hdfe2__
	
	keep if year == 2018 | year == 2020
	bysort zipcode (year): carryforward ln_wagebill, replace
	gen n_hhlds = exp(ln_n_hhdls)
	bysort zipcode (year): carryforward n_hhlds, replace
	keep if counterfactual == 1
	rename (ln_wagebill n_hhlds) (ln_wagebill_pre n_hhlds_pre)
	
	keep zipcode year ln_wagebill ln_wagebill_pre n_hhlds_pre ///
	    p_ln_wagebill p_ln_wagebill_with_fe __hdfe1__ __hdfe2__
	order zipcode year ln_wagebill ln_wagebill_pre n_hhlds_pre ///
	    p_ln_wagebill p_ln_wagebill_with_fe __hdfe1__ __hdfe2__
	save_data "../output/ln_wagebill_cf_predictions.dta", ///
	    key(zipcode year) replace
end

program process_counterfactual_data
    syntax, in_cf_mw(str) instub(str) controls(str)
	
	use zipcode year_month year month ///
	    counterfactual exp_ln_mw_tot using ///
	    "`in_cf_mw'/zipcode_experienced_mw_cfs.dta", clear
	
    keep if (year == 2020 & month == 1)
	rename exp_ln_mw_tot exp_ln_mw_tot_18_avg_cf
	gen fed_mw_cf = 7.25*1.1 if counterfactual == "fed_10pc"
	replace fed_mw_cf = 15 if counterfactual == "fed_15usd"
	replace fed_mw_cf = 9 if counterfactual == "fed_9usd"
	save "../temp/counterfactual.dta", replace

	use "`instub'/all_zipcode_months.dta", clear
	keep if (year == 2019 & month == 12)
	keep zipcode cbsa10 actual_mw
	expand 3
	bysort zipcode: gen counterfactual = "fed_10pc" if _n == 1
	bysort zipcode: replace counterfactual = "fed_15usd" if _n == 2
	bysort zipcode: replace counterfactual = "fed_9usd" if _n == 3
	merge 1:1 zipcode counterfactual using "../temp/counterfactual.dta", ///
		nogen keep(3)
	egen actual_mw_cf = rowmax(actual_mw fed_mw_cf)
	gen ln_mw_cf = log(actual_mw_cf)
	drop actual_mw fed_mw_cf actual_mw_cf year_month month
	preserve
	    keep if counterfactual == "fed_10pc"
		drop counterfactual
		save_data "../temp/counterfactual_fed_10pc.dta", ///
		    key(zipcode) log(none) replace
	restore
	preserve
	    keep if counterfactual == "fed_15usd"
		drop counterfactual
		save_data "../temp/counterfactual_fed_15usd.dta", ///
		    key(zipcode) log(none) replace
	restore
	preserve
	    keep if counterfactual == "fed_9usd"
		drop counterfactual
		save_data "../temp/counterfactual_fed_9usd.dta", ///
		    key(zipcode) log(none) replace
	restore
end



main
