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
	local cluster "statefips"
	
	
	** STATIC
	load_data, instub(`instub')
	
	reghdfe D.ln_med_rent_var d_ln_mw d_ln_mw_int d_exp_ln_mw d_exp_ln_mw_int, nocons absorb(year_month) cluster(statefips)

	
	
end


program load_data
    syntax, instub(str)

	use "`instub'/baseline_zipcode_months.dta", clear

	bys statefips: egen share_resid_state_med = median(share_residents_lowinc)
	bys statefips: egen share_work_state_med  = median(share_workers_lowinc)
	
	gen share_resid_above_med_st = (share_residents_lowinc > share_resid_state_med)
	gen share_work_above_med_st  = (share_workers_lowinc   > share_work_state_med)

	drop share_resid_state_med share_work_state_med
	
	xtset zipcode_num year_month
	
	gen d_ln_mw     = D.ln_mw
	gen d_exp_ln_mw = D.exp_ln_mw
	
	gen d_ln_mw_int     = d_ln_mw*share_work_above_med_st
	gen d_exp_ln_mw_int = d_exp_ln_mw*share_resid_above_med_st
end


main
