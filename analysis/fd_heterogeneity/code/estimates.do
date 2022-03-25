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
	
	reghdfe D.ln_rents c.D.mw_res#i.sh_workers_under1250_above_med ///
	    c.D.mw_wkp_tot_17#i.sh_res_under1250_above_med ///
	    D.(`controls'), nocons ///
		absorb(year_month) cluster(`cluster_vars')
end

main
