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
	local estlabels "`r(estlabels_with_lagged_y)'"

	horse_race_models, depvar(ln_med_rent_psqft_sfcc) w(5) ///
		absorb(year_month) cluster(statefips)
	esttab * using "`outstub'/horse_race.tex", compress se replace substitute(\_ _) 	///
		keep(*.ln_mw *.ln_med_rent_psqft_sfcc) ///
		order(F5D.ln_mw F4D.ln_mw F3D.ln_mw F2D.ln_mw FD.ln_mw D.ln_mw ///
		LD.ln_mw L2D.ln_mw L3D.ln_mw L4D.ln_mw L5D.ln_mw LD.ln_med_rent_psqft_sfcc) ///
		coeflabels(`estlabels') ///
		stats(k cumsum_b cumsum_V k p_value_F r2 N, ///
			fmt(%s1 %s7 %s7 %s1 %9.3f %9.3f %9.0gc) ///
		labels("\vspace{-2mm}" "Cumulative effect" " " "\hline" "P-value no pretrends" ///
			"R-squared" "Observations")) /// 
		star(* 0.10 ** 0.05 *** 0.01) 	///
		mtitles("DiD" "\shortstack{Distributed \\ leads and lags}" "\shortstack{Distributed \\ Lags}" ///
		"\shortstack{AB Distributed \\ leads and lags}" "\shortstack{AB Distributed \\ Lags}" ///
		"\shortstack{MW Distributed \\ leads and lags}" "\shortstack{MW Distributed \\ Lags}") nonote
end

program horse_race_models
    syntax, depvar(str) w(int) absorb(str) cluster(str) 
	
    eststo clear
	define_controls
	local emp_ctrls "`r(emp_ctrls)'"
	local estcount_ctrls "`r(estcount_ctrls)'"
	local avgwwage_ctrls "`r(avgwwage_ctrls)'"
	local controls `"`emp_ctrls' `estcount_ctrls' `avgwwage_ctrls'"'

	local lincomest_coeffs "D1.ln_mw + LD.ln_mw"
	local pretrend_test "(F1D.ln_mw = 0)"
	forvalues i = 2(1)`w'{
		local lincomest_coeffs "`lincomest_coeffs' + L`i'D.ln_mw"
	    local pretrend_test " `pretrend_test' (F`i'D.ln_mw = 0)"
	}
	di "`lincomest_coeffs'"

	eststo: qui reghdfe D.`depvar' D.ln_mw D.(`controls'),	///
		absorb(`absorb') vce(cluster `cluster') nocons

	eststo: qui reghdfe D.`depvar' L(-`w'/`w').D.ln_mw D.(`controls'), ///
		absorb(`absorb') vce(cluster `cluster') nocons
	test `pretrend_test'
	estadd scalar p_value_F = r(p)
	estadd local k ""
	add_cumsum, coefficients(`lincomest_coeffs') i(2)
		
	eststo: qui reghdfe D.`depvar' L(0/`w').D.ln_mw D.(`controls'), ///
		absorb(`absorb') vce(cluster `cluster') nocons
	estadd local k ""
	add_cumsum, coefficients(`lincomest_coeffs') i(3)
	
	eststo: qui ivreghdfe D.`depvar' L(-`w'/`w').D.ln_mw (L.D.`depvar' = L2.D.`depvar') D.(`controls'), ///
		absorb(`absorb') cluster (`cluster') nocons
	test `pretrend_test'
	estadd scalar p_value_F = r(p)
	estadd local k ""
	add_cumsum, coefficients(`lincomest_coeffs') i(4)

	eststo: qui ivreghdfe D.`depvar' L(0/`w').D.ln_mw (L.D.`depvar' = L2.D.`depvar') D.(`controls'), ///
		absorb(`absorb') cluster (`cluster') nocons
	add_cumsum, coefficients(`lincomest_coeffs') i(5)
		
	eststo: qui ivreghdfe D.`depvar' L(-`w'/`w').D.ln_mw (L.D.`depvar' = L6.D.ln_mw) D.(`controls'), ///
		absorb(`absorb') cluster (`cluster') nocons
	test `pretrend_test'
	estadd scalar p_value_F = r(p)
	estadd local k ""
	add_cumsum, coefficients(`lincomest_coeffs') i(6)
		
	eststo: qui ivreghdfe D.`depvar' L(0/`w').D.ln_mw (L.D.`depvar' = L6.D.ln_mw) D.(`controls'), ///
		absorb(`absorb') cluster (`cluster') nocons
	estadd local k ""
	add_cumsum, coefficients(`lincomest_coeffs') i(7)

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

	estadd local cumsum_b = "0`b_digits'`star'": est`i'
	estadd local cumsum_V = "(0`se_digits')":  est`i'
	*estadd scalar cumsum_V = V[1,1]^.5: reg_`i'
end



main
