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

	reghdfe D.ln_rents c.D.mw_res#i.high_mw_wrks ///
	    c.D.mw_wkp_tot_17#i.high_mw_res ///
	    D.(`controls'), nocons ///
		absorb(year_month##high_mw_wrks##high_mw_res) cluster(`cluster_vars')
end


program load_and_clean
    syntax, instub(str) incross(str)

	use "`instub'/zipcode_months.dta" if baseline_sample == 1, clear
	xtset zipcode_num year_month

	merge m:1 zipcode using "`incross'/zipcode_cross.dta", nogen ///
	    keep(3) keepusing(sh_mw_wkrs_statutory sh_workers_under29_2013 ///
		sh_residents_under29_2013 sh_residents_underHS_2013 ///
		sh_residents_under1250_2013 sh_workers_underHS_2013 ///
		sh_workers_under1250_2013 sh_residents_accomm_food_2013 ///
		sh_workers_accomm_food_2013)
	rename *_2013 *
	rename *residents* *res*
	
	foreach var in sh_mw_wkrs_statutory sh_workers_accomm_food sh_workers_underHS ///
	    sh_res_accomm_food sh_res_underHS {
	    bys statefips: egen `var'_med = median(`var')
	    gen `var'_above_med = (`var'   > `var'_med)
	    drop `var'_med

	    gen resint_`var' = mw_res*`var'_above_med
	    gen wkpint_`var' = mw_wkp_tot_17*`var'_above_med
	}
	
	gen high_mw_wrks = sh_workers_underHS_above_med*sh_workers_accomm_food_above_med
	gen high_mw_res  = sh_res_underHS_above_med*sh_res_accomm_food_above_med

	xtset zipcode_num year_month
end


main
