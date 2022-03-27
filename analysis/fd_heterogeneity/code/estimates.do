clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 
	
program main
	local instub  "../temp"
	local outstub "../output"
	
	define_controls
	local controls     "`r(economic_controls)'"
	local cluster_vars "statefips"

	use "`instub'/baseline_sample_with_vars_for_het.dta", clear
	xtset zipcode_num year_month
	
	reghdfe D.ln_rents c.D.mw_res ///
	    c.D.mw_wkp_tot_17#i.public_housing ///
	    D.(`controls'), nocons ///
		absorb(year_month##public_housing) cluster(`cluster_vars')
	
    reghdfe D.ln_rents c.D.mw_res ///
	    c.D.mw_wkp_tot_17#i.high_res_mw ///
	    D.(`controls'), nocons ///
		absorb(year_month##high_res_mw) ///
		cluster(`cluster_vars')
		
    reghdfe D.ln_rents c.D.mw_res#i.high_work_mw ///
	    c.D.mw_wkp_tot_17 ///
	    D.(`controls'), nocons ///
		absorb(year_month##high_work_mw) ///
		cluster(`cluster_vars')
end

main
