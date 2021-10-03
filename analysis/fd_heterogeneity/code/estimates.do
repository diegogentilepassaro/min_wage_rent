clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub  "../../../drive/derived_large/estimation_samples"
	local outstub "../output"
	
	define_controls
	local controls     "`r(economic_controls)'"
	local cluster_vars "statefips"
	
	** STATIC
	load_and_clean, instub(`instub')

	xtset zipcode_num year_month
	eststo clear
	foreach var in under29 30to54 under1250 above3333 underHS College {
	eststo: reghdfe D.ln_med_rent_var D.ln_mw D.ln_mw_times_wrks_`var' ///
	     D.exp_ln_mw_17 D.exp_ln_mw_times_res_`var', nocons ///
		absorb(year_month) cluster(`cluster_vars')	
	}
    esttab *, se r2
end


program load_and_clean
    syntax, instub(str)

	use "`instub'/baseline_zipcode_months.dta", clear
	
	xtset zipcode_num year_month
		
	foreach var in under29 30to54 under1250 above3333 underHS College {
	    bys statefips: egen sh_res_`var'_med = median(sh_residents_`var'_2014)
	    bys statefips: egen sh_ws_`var'_med  = median(sh_workers_`var'_2014)	
	    
		gen above_med_st_res_`var'  = (sh_residents_`var'_2014 > sh_res_`var'_med)
	    gen above_med_st_wrks_`var' = (sh_workers_`var'_2014   > sh_ws_`var'_med)
	    drop *_med
		
	    gen ln_mw_times_wrks_`var'    = ln_mw*above_med_st_wrks_`var'
	    gen exp_ln_mw_times_res_`var' = exp_ln_mw_17*above_med_st_res_`var'
	}
end


main
