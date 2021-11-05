clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../../../drive/derived_large/stacked_sample"
	local outstub "../output"

	local cluster "cbsa10"
	
	** STATIC
	use "`instub'/stacked_sample.dta", clear
	
    reghdfe d_ln_rents d_ln_mw d_exp_ln_mw ///
	    d_ln_emp_* d_ln_estcount_* d_ln_avgwwage_* , ///
	    nocons absorb(year_month#event_id) cluster(statefips)

	/** DYNAMIC
    reghdfe d_ln_rents d_ln_mw d_exp_ln_mw_17 ///
	    d_ln_emp_* d_ln_estcount_* d_ln_avgwwage_* , ///
	    nocons absorb(year_month#event_id) cluster(cbsa10)*/
end

main
