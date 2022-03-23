clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 
	
program main
	
	local instub  "../../../drive/derived_large/estimation_samples"
	local incross "../../../drive/derived_large/zipcode"
	local outstub "../output"
	
	define_controls
	local controls     "`r(economic_controls)'"
	local cluster_vars "statefips"

	load_and_clean, instub(`instub') incross(`incross')

	reghdfe D.ln_rents D.mw_res D.mw_wkp_tot_17_below ///
	     D.mw_wkp_tot_17_above `controls', nocons ///
		absorb(year_month) cluster(`cluster_vars')	
end


program load_and_clean
    syntax, instub(str) incross(str)

	use "`instub'/zipcode_months.dta", clear
	xtset zipcode_num year_month

	merge m:1 zipcode using "`incross'/zipcode_cross.dta", keepusing(sh_mw_wkrs_statutory)
	keep if baseline_sample
	xtset zipcode_num year_month

	sum sh_mw_wkrs_statutory, d
	local median `r(p50)'

	gen above_median = 0
	replace above_median = 1 if sh_mw_wkrs_statutory > `median'

	gen below_median = 0
	replace below_median = 1 if sh_mw_wkrs_statutory < `median'

	gen mw_wkp_tot_17_above = mw_wkp_tot_17 * above_median
	gen mw_wkp_tot_17_below = mw_wkp_tot_17 * below_median
end


main
