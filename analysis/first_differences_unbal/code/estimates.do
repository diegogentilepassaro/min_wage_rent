clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000

program main
	local instub "../temp"
	local outstub "../output"

	use "`instub'/unbal_fd_rent_panel.dta", clear

	make_results_labels, w(5)
	local estlabels_dyn "`r(estlabels_dyn)'"
	local estlabels_static "`r(estlabels_static)'"


	static_dynamic_comp, depvar(ln_med_rent_psqft_sfcc) absorb(year_month) ///
		cluster(statefips) add_wgt(yes)
	esttab using "`outstub'/static_dynamic_comptable.tex", replace compress se substitute(\_ _) ///
	keep(D.ln_mw) b(%9.4f) se(%9.4f) coeflabels(D.ln_mw "Static Effect") ///
	stats(space cumsum_b cumsum_V space ctrl_wage ctrl_emp ctrl_estab r2 N,  ///
	fmt(%s1 %s7 %s7 %s1 %s3 %s3 %s3 %9.3f %9.0gc) ///
	labels("\vspace{-1mm}" "Cumulative effect" " " "\hline" ///
		"Wage controls" "Employment controls" "Establishment-count controls"  ///
			"R-squared" "Observations")) ///
	mtitles("Baseline" "Unbalanced" "Reweighted")  ///
	star(* 0.10 ** 0.05 *** 0.01) nonote

end 


program static_dynamic_comp 
	syntax, depvar(str) absorb(str) cluster(str) [w(int 5) t_plot(real 1.645) add_wgt(str)]

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

	*baseline 
	reghdfe D.`depvar' L(0/`w').D.ln_mw D.(`controls') if basepanel, absorb(`absorb') vce(cluster `cluster') nocons	
	
	add_cumsum, coefficients(`lincomest_coeffs') i(1)

	local cumsum_b "`r(cumsum_b)'"
	local cumsum_V "`r(cumsum_V)'"

	eststo: qui reghdfe D.`depvar' D.ln_mw D.(`controls') if basepanel, ///
		absorb(`absorb') vce(cluster `cluster') nocons
	comment_table_control, emp("Yes") estab("Yes") wage("Yes") housing("No")
	estadd local space ""
	estadd local cumsum_b "`cumsum_b'"
	estadd local cumsum_V "`cumsum_V'"

	*Unbalanced
	qui reghdfe D.`depvar' L(0/`w').D.ln_mw D.(`controls'), absorb(`absorb' entry_sfcc#year_month) vce(cluster `cluster') nocons	

	add_cumsum, coefficients(`lincomest_coeffs') i(1)

	local cumsum_b "`r(cumsum_b)'"
	local cumsum_V "`r(cumsum_V)'"

	eststo: qui reghdfe D.`depvar' D.ln_mw D.(`controls'), ///
		absorb(`absorb' entry_sfcc#year_month) vce(cluster `cluster') nocons
	comment_table_control, emp("Yes") estab("Yes") wage("Yes") housing("No")
	estadd local space ""
	estadd local cumsum_b "`cumsum_b'"
	estadd local cumsum_V "`cumsum_V'"

	if "`add_wgt'"=="yes" {
		use "../../first_differences_wgt/temp/fd_rent_panel.dta", clear
		qui reghdfe D.`depvar' L(0/`w').D.ln_mw D.(`controls') [pw = wgt_cbsa100], absorb(`absorb') vce(cluster `cluster') nocons	

		add_cumsum, coefficients(`lincomest_coeffs') i(1)

		local cumsum_b "`r(cumsum_b)'"
		local cumsum_V "`r(cumsum_V)'"

		eststo: qui reghdfe D.`depvar' D.ln_mw D.(`controls') [pw = wgt_cbsa100], ///
			absorb(`absorb') vce(cluster `cluster') nocons
		comment_table_control, emp("Yes") estab("Yes") wage("Yes") housing("No")
		estadd local space ""
		estadd local cumsum_b "`cumsum_b'"
		estadd local cumsum_V "`cumsum_V'"
	}

end 







program add_cumsum, rclass
	syntax, coefficients(str) i(int)
	lincomest `coefficients'
	mat b = e(b)
	mat V = e(V)
	local b_digits = round(b[1,1], 0.0001)
	local se_digits = round(V[1,1]^.5, 0.0001)
	if abs(b[1,1]/(V[1,1]^.5)) > 1.96 {
		local star = "\sym{**}"
	}
	else if abs(b[1,1]/(V[1,1]^.5)) > 1.65 {
		local star = "\sym{*}"
	}
	else {
		local star = ""
	}

	local cumsum_b = "0`b_digits'`star'"
	local cumsum_V = "(0`se_digits')"

	return local cumsum_b `cumsum_b'
	return local cumsum_V `cumsum_V'
	*estadd scalar cumsum_V = V[1,1]^.5: reg_`i'
end

program comment_table_control
	syntax, emp(str) estab(str) wage(str) housing(str)

	estadd local ctrl_emp   "`emp'"
	estadd local ctrl_estab "`estab'"
	estadd local ctrl_wage  "`wage'"
	estadd local ctrl_building "`housing'"
end


main 