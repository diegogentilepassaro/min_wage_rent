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
	local emp_ctrls "`r(emp_ctrls)'"
	local estcount_ctrls "`r(estcount_ctrls)'"
	local avgwage_ctrls "`r(avgwwage_ctrls)'"
	
	local cluster "statefips"
	
	
	** STATIC
 	use "`instub'/baseline_zipcode_months.dta", clear
	xtset zipcode_num year_month

	estimate_dist_lag_model, depvar(ln_med_rent_var) ///
		dyn_var(exp_ln_mw) w(0) stat_var(ln_mw) test_equality ///
		controls(`controls') absorb(year_month) cluster(`cluster') ///
		model_name(static_stat) outfolder("../temp")

	estimate_dist_lag_model, depvar(ln_med_rent_var) ///
		dyn_var(exp_ln_mw) w(0) stat_var(ln_mw) test_equality ///
		controls(" ") absorb(year_month) cluster(`cluster') ///
		model_name(static_stat_nocontrol) outfolder("../temp")

	estimate_dist_lag_model, depvar(ln_med_rent_var) ///
		dyn_var(exp_ln_mw) w(0) stat_var(ln_mw) test_equality ///
		controls(`controls') ab absorb(year_month) cluster(`cluster') ///
		model_name(static_stat_AB) outfolder("../temp")

	estimate_dist_lag_model, depvar(ln_med_rent_var) ///
		dyn_var(exp_ln_mw) w(0) stat_var(ln_mw) test_equality ///
		controls(" ") ab absorb(year_month) cluster(`cluster') ///
		model_name(static_stat_AB_nocontrol) outfolder("../temp")

	estimate_dist_lag_model, depvar(ln_med_rent_var) ///
		dyn_var(exp_ln_mw) w(0) stat_var(ln_mw) test_equality wgt(wgt_cbsa100) ///
		controls(`controls') absorb(year_month) cluster(`cluster') ///
		model_name(static_stat_wgt) outfolder("../temp")

	use "`instub'/all_zipcode_months.dta", clear
	xtset zipcode_num year_month

	estimate_dist_lag_model, depvar(ln_med_rent_var) ///
		dyn_var(exp_ln_mw) w(0) stat_var(ln_mw) test_equality ///
		controls(`controls') absorb(year_month) cluster(`cluster') ///
		model_name(static_stat_unbal) outfolder("../temp")
	
	estimate_dist_lag_model, depvar(ln_med_rent_var) ///
		dyn_var(exp_ln_mw) w(0) stat_var(ln_mw) test_equality wgt(wgt_cbsa100) ///
		controls(`controls') absorb(year_month) cluster(`cluster') ///
		model_name(static_stat_unbal_wgt) outfolder("../temp")

		local outstub "../output"
	use ../temp/estimates_static_stat.dta, clear
	foreach ff in static_stat_nocontrol static_stat_AB static_stat_AB_nocontrol static_stat_wgt ///
				  static_stat_unbal static_stat_unbal_wgt {
		append using ../temp/estimates_`ff'.dta
	}
	save             `outstub'/estimates_static.dta, replace
	export delimited `outstub'/estimates_static.csv, replace
	
	** DYNAMIC
	use "`instub'/baseline_zipcode_months.dta", clear
	xtset zipcode_num year_month

	local treatlist `" "exp_" "" "'

	foreach treat in `treatlist' {

		if "`treat'"=="exp_" {
			local stat ""
		} 
		else {
			local stat "exp_"
		}

		local ctrls_list ""
		local ctrls_name ""
		foreach c in emp avgwage estcount {

			local ctrls_list `"`ctrls_list' ""``c'_ctrls'"""'
		    local ctrls_name `"`ctrls_name'_`c'"'

		    estimate_dist_lag_model, depvar(ln_med_rent_var) ///
			    dyn_var("`treat'ln_mw") w(6) stat_var("`stat'ln_mw") ///
				controls("`ctrls_list'") absorb(year_month) cluster(`cluster') ///
				model_name("`treat'ln_mw_dynamic`ctrls_name'") outfolder("../temp")
		}
	} 
		
	clear		
	foreach ff in exp_ln_mw_dynamic_emp exp_ln_mw_dynamic_emp_avgwage exp_ln_mw_dynamic_emp_avgwage_estcount ///
				  ln_mw_dynamic_emp ln_mw_dynamic_emp_avgwage ln_mw_dynamic_emp_avgwage_estcount {
		append using ../temp/estimates_`ff'.dta
	}
	save             `outstub'/estimates_dynamic.dta, replace
	export delimited `outstub'/estimates_dynamic.csv, replace
end

main
