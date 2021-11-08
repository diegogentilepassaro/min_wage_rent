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
	egen x_id = group(event_id zipcode)
	xtset x_id year_month
	
    reghdfe d_ln_rents d_ln_mw d_exp_ln_mw ///
	    d_ln_emp_* d_ln_estcount_* d_ln_avgwwage_* , ///
	    nocons absorb(year_month#event_id) cluster(cbsa10)
		
    reghdfe ln_rents ln_rents ln_mw exp_ln_mw ///
	    ln_emp_* ln_estcount_* ln_avgwwage_* , ///
	    nocons absorb(zipcode_num#event_id year_month#event_id) cluster(cbsa10)

	** DYNAMIC
    reghdfe d_ln_rents L(-1/1).d_ln_mw L(-1/1).d_exp_ln_mw ///
	    d_ln_emp_* d_ln_estcount_* d_ln_avgwwage_* , ///
	    nocons absorb(year_month#event_id) cluster(cbsa10)
		
    reghdfe ln_rents L(-1/1).ln_mw L(-1/1).exp_ln_mw ///
	    ln_emp_* ln_estcount_* ln_avgwwage_* , ///
	    nocons absorb(zipcode_num#event_id year_month#event_id) cluster(cbsa10)
end

main
