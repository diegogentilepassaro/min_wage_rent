clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../../../drive/derived_large/stacked_sample"
	local logfile "../output/data_file_manifest.log"

	local cluster "cbsa10"
	
	use "`instub'/stacked_sample_window6.dta", clear
	*describe d_ln_emp_* d_ln_estcount_* d_ln_avgwwage_*, varlist
	*local controls = r(varlist)
	
    estimate_stacked_model, depvar(d_ln_rents) res_mw_var(d_ln_mw) ///
	    wkp_mw_var(d_exp_ln_mw) controls(" ") ///
	    absorb(year_month#event_id) cluster(statefips) ///
		model_name(stacked_static_w6) outfolder("../temp")
		
    estimate_dyn_stacked_model, depvar(d_ln_rents) res_mw_var(d_ln_mw) ///
	    wkp_mw_var(d_exp_ln_mw) controls(" ") ///
	    absorb(year_month#event_id) cluster(statefips) ///
		model_name(stacked_dyn_w6) outfolder("../temp")
		
	use "`instub'/stacked_sample_window3.dta", clear
    estimate_stacked_model, depvar(d_ln_rents) res_mw_var(d_ln_mw) ///
	    wkp_mw_var(d_exp_ln_mw) controls(" ") ///
	    absorb(year_month#event_id) cluster(statefips) ///
		model_name(stacked_static_w3) outfolder("../temp")
		
    estimate_dyn_stacked_model, depvar(d_ln_rents) res_mw_var(d_ln_mw) ///
	    wkp_mw_var(d_exp_ln_mw) controls(" ") w(3) ///
	    absorb(year_month#event_id) cluster(statefips) ///
		model_name(stacked_dyn_w3) outfolder("../temp")
		
	use "`instub'/stacked_sample_window9.dta", clear
    estimate_stacked_model, depvar(d_ln_rents) res_mw_var(d_ln_mw) ///
	    wkp_mw_var(d_exp_ln_mw) controls(" ") ///
	    absorb(year_month#event_id) cluster(statefips) ///
		model_name(stacked_static_w9) outfolder("../temp")
		
    estimate_dyn_stacked_model, depvar(d_ln_rents) res_mw_var(d_ln_mw) ///
	    wkp_mw_var(d_exp_ln_mw) controls(" ") w(9) ///
	    absorb(year_month#event_id) cluster(statefips) ///
		model_name(stacked_dyn_w9) outfolder("../temp")
		
	use ../temp/estimates_stacked_static_w6.dta, clear
	foreach ff in stacked_static_w3 stacked_static_w9 {
		append using ../temp/estimates_`ff'.dta
	}
	save_data "../output/estimates_stacked_static.dta", ///
	    key(model var at) log(`logfile') replace
	export delimited "../output/estimates_stacked_static.csv", replace
	
	use ../temp/estimates_stacked_dyn_w6.dta, clear
	foreach ff in stacked_dyn_w3 stacked_dyn_w9 {
		append using ../temp/estimates_`ff'.dta
	}
	save_data "../output/estimates_stacked_dyn.dta", ///
	    key(model var at) log(`logfile') replace
	export delimited "../output/estimates_stacked_dyn.csv", replace
end

main
