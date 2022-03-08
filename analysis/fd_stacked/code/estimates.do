clear all
set more off
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
    local instub "../../../drive/derived_large/estimation_samples"
    local logfile "../output/data_file_manifest.log"

    local cluster "statefips"
    local absorb  "year_month#event_id"

	local mw_wkp_var "d_mw_wkp_tot_17"

	foreach w in 3 6 9 {
		use "`instub'/stacked_sample_window`w'.dta", clear
		describe d_ln_emp_* d_ln_estcount_* d_ln_avgwwage_*, varlist
		local controls = r(varlist)
	
		estimate_stacked_model if !missing(d_ln_rents), depvar(`mw_wkp_var') ///
			mw_var1(d_mw_res) mw_var2(d_mw_res) ///
			controls(`controls') absorb(`absorb') cluster(`cluster') ///
			model_name(mw_wkp_on_res_mw_w`w') outfolder("../temp")

		estimate_stacked_model, depvar(d_ln_rents) ///
			mw_var1(d_mw_res) mw_var2(d_mw_res) ///
			controls(`controls') absorb(`absorb') cluster(`cluster') ///
			model_name(static_mw_res_w`w') outfolder("../temp")
			
		estimate_stacked_model, depvar(d_ln_rents) ///
			mw_var1(`mw_wkp_var') mw_var2(`mw_wkp_var') ///
			controls(`controls') absorb(`absorb') cluster(`cluster') ///
			model_name(static_mw_wkp_w`w') outfolder("../temp")

		estimate_stacked_model, depvar(d_ln_rents) ///
			mw_var1(d_mw_res) mw_var2(`mw_wkp_var') ///
			controls(`controls') absorb(`absorb') cluster(`cluster') ///
			model_name(static_both_w`w') outfolder("../temp")

		estimate_dyn_stacked_model, depvar(d_ln_rents) w(`w') ///
			res_mw_var(d_mw_res) wkp_mw_var(`mw_wkp_var') ///
			controls(`controls') absorb(`absorb') cluster(`cluster') ///
			model_name(mw_wkp_only_dynamic_w`w') outfolder("../temp")

		use ../temp/estimates_mw_wkp_on_res_mw_w`w'.dta, clear
		foreach ff in static_mw_res_w`w' static_mw_wkp_w`w' static_both_w`w' {
			append using ../temp/estimates_`ff'.dta
		}
		save_data "../output/estimates_stacked_static_w`w'.dta", ///
			key(model var at) log(`logfile') replace
		export delimited "../output/estimates_stacked_static_w`w'.csv", replace

		use ../temp/estimates_mw_wkp_only_dynamic_w`w'.dta, clear
		save_data "../output/estimates_stacked_dyn_w`w'.dta", ///
			key(model var at) log(`logfile') replace
		export delimited "../output/estimates_stacked_dyn_w`w'.csv", replace
	} 
end

main
