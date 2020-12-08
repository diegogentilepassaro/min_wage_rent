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
		b(%9.4f) se(%9.4f) coeflabels(`estlabels_static') ///
		stats(ctrl_wage ctrl_emp ctrl_estab r2 N, fmt(%s3 %s3 %s3 %9.3f %9.0gc) ///
		labels("Wage controls" "Employment controls" "Establishment-count controls" ///
			"R-squared" "Observations")) star(* 0.10 ** 0.05 *** 0.01) ///
		nonote nomtitles

	run_static_model_trend, depvar(ln_med_rent_psqft_sfcc) absorb(year_month) cluster(statefips)
	esttab * using "`outstub'/fd_table_trend.tex", keep(D.ln_mw) compress se replace substitute(\_ _) 	///
		b(%9.4f) se(%9.4f) coeflabels(`estlabels_static') ///
		stats(zs_trend zs_trend_sq r2 N, fmt(%s3 %s3 %9.3f %9.0gc) ///
		labels("Zipcode-specifc linear trend" "Zipcode-specific quadratic trend" ///
			"R-squared" "Observations")) star(* 0.10 ** 0.05 *** 0.01) nonote nomtitles

	* Dynamic Model
	run_dynamic_model, depvar(ln_med_rent_psqft_sfcc) absorb(year_month) ///
		cluster(statefips)
	esttab reg_1 reg_2 reg_3 reg_4 reg_5 using "`outstub'/fd_dynamic_table.tex", ///
		keep(*.ln_mw) compress se replace substitute(\_ _) ///
		b(%9.4f) se(%9.4f) coeflabels(`estlabels_dyn') ///
		stats(k cumsum_b cumsum_V k p_value_F ctrl_wage ctrl_emp ctrl_estab r2 N, ///
			fmt(%s1 %s7 %s7 %s1 %9.3f %s3 %s3 %s3 %9.3f %9.0gc) ///
		labels("\vspace{-2mm}" "Cumulative effect" " " "\hline" "P-value no pretrends" ///
			"Wage controls" "Employment controls" "Establishment-count controls"  ///
			"R-squared" "Observations")) ///
		star(* 0.10 ** 0.05 *** 0.01) nonote nomtitles
end

program run_static_model
	syntax, depvar(str) absorb(str) cluster(str)

	eststo clear

	define_controls
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
	syntax, depvar(str) absorb(str) cluster(str) [control(str)]

	define_controls
	local emp_ctrls "`r(emp_ctrls)'"
	local estcount_ctrls "`r(estcount_ctrls)'"
	local avgwwage_ctrls "`r(avgwwage_ctrls)'"
	local controls `"`emp_ctrls' `estcount_ctrls' `avgwwage_ctrls'"'

	eststo clear
	eststo: reghdfe D.`depvar' D.ln_mw, ///
		vce(cluster `cluster') nocons absorb(`absorb') 
	comment_table, trend_lin("No") trend_sq("No") econ_con("No")

	eststo: reghdfe D.`depvar' D.ln_mw,	///
		vce(cluster `cluster') nocons absorb(`absorb' i.zipcode) 
	comment_table, trend_lin("Yes") trend_sq("No") econ_con("No")

	eststo: reghdfe D.`depvar' D.ln_mw, ///
		vce(cluster `cluster') nocons absorb(`absorb' i.zipcode c.trend_times2#i.zipcode) 
	comment_table, trend_lin("Yes") trend_sq("Yes") econ_con("No")

	if "`control'"=="yes" {
		eststo: reghdfe D.`depvar' D.ln_mw D.(`controls'), ///
			vce(cluster `cluster') nocons absorb(`absorb') 
		comment_table, trend_lin("No") trend_sq("No") econ_con("Yes")

		eststo: reghdfe D.`depvar' D.ln_mw D.(`controls'),	///
			vce(cluster `cluster') nocons absorb(`absorb' i.zipcode) 
		comment_table, trend_lin("Yes") trend_sq("No") econ_con("Yes")

		eststo: reghdfe D.`depvar' D.ln_mw D.(`controls'), ///
			vce(cluster `cluster') nocons absorb(`absorb' i.zipcode c.trend_times2#i.zipcode) 
		comment_table, trend_lin("Yes") trend_sq("Yes") econ_con("Yes")
	}



end

program run_dynamic_model
	syntax, depvar(str) absorb(str) cluster(str) [w(int 5) t_plot(real 1.645) offset(real 0.09)]

	eststo clear
	define_controls
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
	estadd local k ""

	add_cumsum, coefficients(`lincomest_coeffs') i(1)

	eststo reg_2: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw D.(`avgwwage_ctrls') `if', ///
		absorb(`absorb') vce(cluster `cluster') nocons
	comment_table_control, emp("No") estab("No") wage("Yes") housing("No")

	test `pretrend_test'
	estadd scalar p_value_F = r(p)
	estadd local k ""

	add_cumsum, coefficients(`lincomest_coeffs') i(2)

	eststo reg_3: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw D.(`emp_ctrls') `if', ///
		absorb(`absorb') vce(cluster `cluster') nocons
	comment_table_control, emp("Yes") estab("No") wage("No") housing("No")

	test `pretrend_test'
	estadd scalar p_value_F = r(p)
	estadd local k ""

	add_cumsum, coefficients(`lincomest_coeffs') i(3)

	eststo reg_4: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw `if' D.(`estcount_ctrls'), ///
		absorb(`absorb') vce(cluster `cluster') nocons
	comment_table_control, emp("No") estab("Yes") wage("No") housing("No")

	test `pretrend_test'
	estadd scalar p_value_F = r(p)
	estadd local k ""

	add_cumsum, coefficients(`lincomest_coeffs') i(4)

	eststo reg_5: reghdfe D.`depvar' L(-`w'/`w').D.ln_mw ///
		D.(`avgwwage_ctrls') D.(`emp_ctrls') D.(`estcount_ctrls') `if', ///
		absorb(`absorb') vce(cluster `cluster') nocons
	comment_table_control, emp("Yes") estab("Yes") wage("Yes") housing("No")

	test `pretrend_test'
	estadd scalar p_value_F = r(p)
	estadd local k ""

	add_cumsum, coefficients(`lincomest_coeffs') i(5)
end

program comment_table_control
	syntax, emp(str) estab(str) wage(str) housing(str)

	estadd local ctrl_emp   "`emp'"
	estadd local ctrl_estab "`estab'"
	estadd local ctrl_wage  "`wage'"
	estadd local ctrl_building "`housing'"
end

program add_cumsum
	syntax, coefficients(str) i(int)
	lincomest `coefficients'
	mat b = e(b)
	mat V = e(V)
	local b_digits = round(b[1,1], 0.001)
	local se_digits = round(V[1,1]^.5, 0.001)
	if abs(b[1,1]/(V[1,1]^.5)) > 1.96 {
		local star = "\sym{**}"
	}
	else if abs(b[1,1]/(V[1,1]^.5)) > 1.65 {
		local star = "\sym{*}"
	}
	else {
		local star = ""
	}

	estadd local cumsum_b = "0`b_digits'`star'": reg_`i'
	estadd local cumsum_V = "(0`se_digits')":  reg_`i'
	*estadd scalar cumsum_V = V[1,1]^.5: reg_`i'
end

program comment_table
	syntax, trend_lin(str) trend_sq(str) econ_con(str)

	estadd local zs_trend 		"`trend_lin'"
	estadd local zs_trend_sq 	"`trend_sq'"
	estadd local econ_con       "`econ_con'"
end


main
