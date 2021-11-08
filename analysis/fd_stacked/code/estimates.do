clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../../../drive/derived_large/stacked_sample"
	local outstub "../output"

	local cluster "cbsa10"
	
	use "`instub'/stacked_sample_window6.dta", clear
	describe d_ln_emp_* d_ln_estcount_* d_ln_avgwwage_*, varlist
	local controls = r(varlist)
	
	** STATIC
    estimate_stacked_model, depvar(d_ln_rents) res_mw_var(d_ln_mw) ///
	    wkp_mw_var(d_exp_ln_mw) controls(`controls') ///
	    absorb(year_month#event_id) cluster(statefips) ///
		model_name(stacked_static_w6) outfolder("../temp")
		
	use "`instub'/stacked_sample_window3.dta", clear
    estimate_stacked_model, depvar(d_ln_rents) res_mw_var(d_ln_mw) ///
	    wkp_mw_var(d_exp_ln_mw) controls(`controls') ///
	    absorb(year_month#event_id) cluster(statefips) ///
		model_name(stacked_static_w3) outfolder("../temp")
		
	use "`instub'/stacked_sample_window9.dta", clear
    estimate_stacked_model, depvar(d_ln_rents) res_mw_var(d_ln_mw) ///
	    wkp_mw_var(d_exp_ln_mw) controls(`controls') ///
	    absorb(year_month#event_id) cluster(statefips) ///
		model_name(stacked_static_w9) outfolder("../temp")
		
	use ../temp/estimates_stacked_static_w6.dta, clear
	foreach ff in stacked_static_w3 stacked_static_w9 {
		append using ../temp/estimates_`ff'.dta
	}
	save             `outstub'/estimates_stacked_static.dta, replace
	export delimited `outstub'/estimates_stacked_static.csv, replace
	
	/** DYNAMIC
    reghdfe d_ln_rents d_ln_mw ///
		F3_d_exp_ln_mw F2_d_exp_ln_mw F1_d_exp_ln_mw ///
		d_exp_ln_mw L1_d_exp_ln_mw L2_d_exp_ln_mw L3_d_exp_ln_mw, ///
	    nocons absorb(year_month#event_id) cluster(statefips)
		
    reghdfe d_ln_rents d_ln_mw ///
	    F6_d_exp_ln_mw F5_d_exp_ln_mw F4_d_exp_ln_mw ///
		F3_d_exp_ln_mw F2_d_exp_ln_mw F1_d_exp_ln_mw ///
		d_exp_ln_mw L1_d_exp_ln_mw L2_d_exp_ln_mw L3_d_exp_ln_mw ///
		L4_d_exp_ln_mw L5_d_exp_ln_mw L6_d_exp_ln_mw, ///
	    nocons absorb(year_month#event_id) cluster(statefips)*/

end

main
