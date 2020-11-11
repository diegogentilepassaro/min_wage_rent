clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../temp"
	local outstub "../output"

	use "`instub'/fd_rent_panel.dta", clear

	make_results_labels, w(5)
	local estlabels_dyn "`r(estlabels_dyn)'"
	local estlabels_static "`r(estlabels_static)'"

	* Static Model
	run_static_model, depvar(ln_med_rent_psqft_sfcc) absorb(year_month) cluster(statefips)
	esttab * using "`outstub'/fd_table.tex", keep(D.ln_mw) compress se replace substitute(\_ _) ///
		coeflabels(`estlabels_static') ///
		stats(ctrl_wage ctrl_emp ctrl_estab r2 N, fmt(%s3 %s3 %s3 %9.3f %9.0gc) ///
		labels("Wage controls" "Employment controls" "Establishment-count controls" ///
			"R-squared" "Observations")) star(* 0.10 ** 0.05 *** 0.01) ///
		nonote nomtitles

	run_static_model_trend, depvar(ln_med_rent_psqft_sfcc) absorb(year_month) cluster(statefips)
	esttab * using "`outstub'/fd_table_trend.tex", keep(D.ln_mw) compress se replace substitute(\_ _) 	///
		coeflabels(`estlabels_static') ///
		stats(zs_trend zs_trend_sq r2 N, fmt(%s3 %s3 %9.3f %9.0gc) ///
		labels("Zipcode-specifc linear trend" "Zipcode-specific quadratic trend" ///
			"R-squared" "Observations")) star(* 0.10 ** 0.05 *** 0.01) nonote nomtitles 

	* Dynamic Model
	run_dynamic_model, depvar(ln_med_rent_psqft_sfcc) absorb(year_month) ///
		cluster(statefips)
	esttab reg_1 reg_2 reg_3 reg_4 reg_5 using "`outstub'/fd_dynamic_table.tex", ///
		keep(*.ln_mw) compress se replace substitute(\_ _) ///
		coeflabels(`estlabels_dyn') ///
		stats(p_value_F ctrl_wage ctrl_emp ctrl_estab r2 N, fmt(%9.3f %s3 %s3 %s3 %9.3f %9.0gc) ///
		labels("P-value no pretrends" "Wage controls" "Employment controls" /// 
			"Establishment-count controls" "R-squared" "Observations")) ///
		star(* 0.10 ** 0.05 *** 0.01) nonote nomtitles

	esttab lincom1 lincom2 lincom3 using "`outstub'/fd_dynamic_lincom_table.tex", ///
		compress se replace coeflabel((1) "Sum of MW effects") ///
		stats(ctrl_wage ctrl_emp ctrl_estab N, fmt(%s3 %s3 %s3 %9.0gc) ///
		labels("Wage controls" "Employment controls" "Establishment-count controls" "Observations")) ///
		star(* 0.10 ** 0.05 *** 0.01) nonote nomtitles
end

program run_static_model
	syntax, depvar(str) absorb(str) cluster(str)

	eststo clear

	define_controls estcount avgwwage
	local emp_ctrls "`r(emp_ctrls)'"
	local estcount_ctrls "`r(estcount_ctrls)'"
	local avgwwage_ctrls "`r(avgwwage_ctrls)'"

	eststo: reghdfe D.`depvar' D.ln_mw,	absorb(`absorb') vce(cluster `cluster') nocons
	comment_table_control, emp("No") estab("No") wage("No") housing("No")

	scalar static_effect = _b[D.ln_mw]
	scalar static_effect_se = _se[D.ln_mw]

	eststo: reghdfe D.`depvar' D.ln_mw D.(`avgwwage_ctrls'), absorb(`absorb' zipcode) vce(cluster `cluster') nocons
	comment_table_control, emp("No") estab("No") wage("Yes") housing("No")

	eststo: reghdfe D.`depvar' D.ln_mw D.(`emp_ctrls'), absorb(`absorb') vce(cluster `cluster') nocons
	comment_table_control, emp("Yes") estab("No") wage("No") housing("No")

	eststo: reghdfe D.`depvar' D.ln_mw D.(`estcount_ctrls'), absorb(`absorb') vce(cluster `cluster') nocons
	comment_table_control, emp("No") estab("Yes") wage("No") housing("No")

	eststo: reghdfe D.`depvar' D.ln_mw D.(`avgwwage_ctrls') D.(`emp_ctrls') D.(`estcount_ctrls'), ///
		absorb(`absorb') vce(cluster `cluster') nocons
	comment_table_control, emp("Yes") estab("Yes") wage("Yes") housing("No")
end 

program run_static_model_trend
	syntax, depvar(str) absorb(str) cluster(str)

	eststo clear
	eststo reg1: reghdfe D.`depvar' D.ln_mw, ///
		absorb(`absorb') ///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("No") trend_sq("No")

	eststo: reghdfe D.`depvar' D.ln_mw,	///
		absorb(`absorb' i.zipcode) ///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("Yes") trend_sq("No")

	eststo: reghdfe D.`depvar' D.ln_mw, ///
		absorb(`absorb' i.zipcode c.trend_times2#i.zipcode) ///
		vce(cluster `cluster') nocons
	comment_table, trend_lin("Yes") trend_sq("Yes")
end

program run_dynamic_model
	syntax, depvar(str) absorb(str) cluster(str) [w(int 5) t_plot(real 1.645) offset(real 0.09)]

	define_controls estcount avgwwage
	local emp_ctrls "`r(emp_ctrls)'"
	local estcount_ctrls "`r(estcount_ctrls)'"
	local avgwwage_ctrls "`r(avgwwage_ctrls)'"

	local lincomest_coeffs "D1.ln_mw + LD.ln_mw"
	local pretrend_test "(F1D.ln_mw = 0)"
	forvalues i = 2(1)`w'{
		local lincomest_coeffs "`lincomest_coeffs' + L`i'D.ln_mw"
	    local pretrend_test " `pretrend_test' (F`i'D.ln_mw = 0)"
	}

	eststo clear
	eststo reg_1: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw, absorb(`absorb') vce(cluster `cluster') nocons
	comment_table_control, emp("No") estab("No") wage("No") housing("No")
	
	test `pretrend_test'
	estadd scalar p_value_F = r(p)

	eststo lincom1: lincomest `lincomest_coeffs'
	comment_table_control, emp("No") estab("No") wage("No") housing("No")

	eststo reg_2: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw D.(`avgwwage_ctrls') `if', ///
		absorb(`absorb') vce(cluster `cluster') nocons
	comment_table_control, emp("No") estab("No") wage("Yes") housing("No")

	test `pretrend_test'
	estadd scalar p_value_F = r(p)

	eststo lincom2: lincomest `lincomest_coeffs'
	comment_table_control, emp("No") estab("No") wage("Yes") housing("No")

	eststo reg_3: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw D.(`emp_ctrls') `if', ///
		absorb(`absorb') vce(cluster `cluster') nocons
	comment_table_control, emp("Yes") estab("No") wage("No") housing("No")

	test `pretrend_test'
	estadd scalar p_value_F = r(p)

	eststo lincom3: lincomest `lincomest_coeffs'
	comment_table_control, emp("No") estab("No") wage("Yes") housing("No")

	eststo reg_4: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw `if' D.(`estcount_ctrls'), ///
		absorb(`absorb') vce(cluster `cluster') nocons
	comment_table_control, emp("No") estab("Yes") wage("No") housing("No")

	test `pretrend_test'
	estadd scalar p_value_F = r(p)

	eststo lincom4: lincomest `lincomest_coeffs'
	comment_table_control, emp("No") estab("Yes") wage("No") housing("No")

	eststo reg_5: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw ///
		D.(`avgwwage_ctrls') D.(`emp_ctrls') D.(`estcount_ctrls') `if', ///
		absorb(`absorb') vce(cluster `cluster') nocons
	comment_table_control, emp("Yes") estab("Yes") wage("Yes") housing("No")

	test `pretrend_test'
	estadd scalar p_value_F = r(p)

	eststo lincom5: lincomest `lincomest_coeffs'
	comment_table_control, emp("Yes") estab("Yes") wage("Yes") housing("No")
end

program define_controls, rclass
	
	foreach ctrl_type in emp estcount avgwwage {
		local var_list "ln_`ctrl_type'_bizserv ln_`ctrl_type'_info ln_`ctrl_type'_manu"
		return local `ctrl_type'_ctrls `var_list'
	}

	local housing_cont   "ln_u1rep_units ln_u1rep_value"
	return local housing_cont "`housing_cont'"
end

program comment_table_control
	syntax, emp(str) estab(str) wage(str) housing(str)

	estadd local ctrl_emp   "`emp'"
	estadd local ctrl_estab "`estab'"
	estadd local ctrl_wage  "`wage'"
	estadd local ctrl_building "`housing'"
end

program comment_table
	syntax, trend_lin(str) trend_sq(str)

	estadd local zs_trend 		"`trend_lin'"
	estadd local zs_trend_sq 	"`trend_sq'"
end

program make_results_labels, rclass
	syntax, w(int)

	
	local estlabels `"D.ln_mw "$\Delta \ln \underline{w}_t""'
	local estlabels `"FD.ln_mw "$\Delta \ln \underline{w}_{t-1}$" `estlabels' LD.ln_mw "$\ln \underline{w}_{t+1}$""'
	forvalues i = 2(1)`w'{
		local estlabels `"F`i'D.ln_mw "$\Delta \ln \underline{w}_{t-`i'}$" `estlabels' L`i'D.ln_mw "$\ln \underline{w}_{t+`i'}$""'
	}

	return local estlabels_dyn "`estlabels'"	

	local estlabels_static `"D.ln_mw "$\Delta \ln \underline{w}_t$""'
	return local estlabels_static "`estlabels_static'"
end 


main
