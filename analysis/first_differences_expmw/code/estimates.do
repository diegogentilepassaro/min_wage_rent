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

	run_models, depvar(ln_med_rent_psqft_sfcc) absorb(year_month) ///
		cluster(statefips)
	esttab using "`outstub'/expmw_static_results.tex", replace compress se substitute(\_ _) ///
		keep(D.ln_mw D.ln_expmw) b(%9.4f) se(%9.4f) ///
		coeflabels(D.ln_mw "$\Delta \ln \underline{w}_{ict}$" D.ln_expmw "$\Delta \ln \underline{w}_{ict}^{\text{exp}}$") ///
		stats(space ctrl_wage ctrl_emp ctrl_estab r2 N, fmt(%s1 %s3 %s3 %s3 %9.3f %9.0gc) ///
		labels("\vspace{-2mm}" "Wage controls" "Employment controls" "Establishment-count controls" "R-squared" "Observations")) ///
		mgroups("$\Delta \ln \underline{w}_{ict}^{\text{exp}}$" "$\Delta \ln y_{ict}$", ///
			pattern(1 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
		nomtitles star(* 0.10 ** 0.05 *** 0.01) nonote


	/* static_dynamic_comp, depvar(ln_med_rent_psqft_sfcc) absorb(year_month) ///
		cluster(statefips)
	esttab using "`outstub'/static_dynamic_comptable.tex", replace compress se substitute(\_ _) ///
	rename(D.ln_expmw D.ln_mw) keep(D.ln_mw) b(%9.4f) se(%9.4f) coeflabels(D.ln_mw "Static Effect") ///
	stats(space cumsum_b cumsum_V space p_value_F ctrl_wage ctrl_emp ctrl_estab r2 N,  ///
	fmt(%s1 %s7 %s7 %s1 %9.3f %s3 %s3 %s3 %9.3f %9.0gc) ///
	labels("\vspace{-1mm}" "Cumulative effect" " " "\hline" "P-value no pretrends" ///
		"Wage controls" "Employment controls" "Establishment-count controls"  ///
			"R-squared" "Observations")) ///
	mtitles("Baseline" "Experienced MW")  ///
	star(* 0.10 ** 0.05 *** 0.01) nonote */
end 

program run_models 
	syntax, depvar(str) absorb(str) cluster(str) [w(int 5)]

	eststo clear

	define_controls
	local controls "`r(economic_controls)'"

	* exp_mw vs actual_mw
	eststo: reghdfe D.ln_expmw D.ln_mw D.(`controls') if !missing(D.ln_med_rent_psqft_sfcc), ///
		absorb(`absorb') vce(cluster `cluster') nocons
	comment_table_control, emp("Yes") estab("Yes") wage("Yes") housing("No")

	estadd local space ""

	*baseline

	eststo: reghdfe D.`depvar' D.ln_mw D.(`controls'), ///
		absorb(`absorb') vce(cluster `cluster') nocons
	comment_table_control, emp("Yes") estab("Yes") wage("Yes") housing("No")
	
	estadd local space ""

	*experienced

	eststo: reghdfe D.`depvar' D.ln_expmw D.(`controls'), ///
		absorb(`absorb') vce(cluster `cluster') nocons
	comment_table_control, emp("Yes") estab("Yes") wage("Yes") housing("No")

	estadd local space ""

	/* reghdfe D.`depvar' c.Dln_exp_mw_totjob##i.ziptreated_ind D.(`controls'), ///
		absorb(`absorb') vce(cluster `cluster') nocons */


	*both 
	eststo: qui reghdfe D.`depvar' D.ln_mw D.ln_expmw D.(`controls'), ///
		absorb(`absorb') vce(cluster `cluster') nocons
	comment_table_control, emp("Yes") estab("Yes") wage("Yes") housing("No")

	estadd local space ""

	
	/* 	local lincomest_coeffs "D1.ln_mw + LD.ln_mw"
	local pretrend_test "(F1D.ln_mw = 0)"
	local lincomest_coeffs_exp "D1.ln_expmw + LD.ln_expmw"
	local pretrend_test_exp "(F1D.ln_expmw = 0)"
	forvalues i = 2(1)`w'{
		local lincomest_coeffs "`lincomest_coeffs' + L`i'D.ln_mw"
	    local pretrend_test " `pretrend_test' (F`i'D.ln_mw = 0)"
		local lincomest_coeffs_exp "`lincomest_coeffs_exp' + L`i'D.ln_expmw"
	    local pretrend_test_exp " `pretrend_test_exp' (F`i'D.ln_expmw = 0)"

	}
	reghdfe D.`depvar' L(0/`w').D.ln_mw D.(`controls'), ///
		absorb(`absorb') vce(cluster `cluster') nocons	
	compute_cumsum, coefficients(`lincomest_coeffs')

	local cumsum_b "`r(cumsum_b)'"
	local cumsum_V "`r(cumsum_V)'"

	ivreghdfe D.`depvar' L(0/`w').D.ln_mw (L.D.`depvar' = L2.D.`depvar') D.(`controls'), ///
		absorb(`absorb') cluster(`cluster') nocons
	compute_longrun, depvar(`depvar')

	local longrun_b "`r(longrun_b)'"
	local longrun_V "`r(longrun_V)'" */
	
	/* estadd local space ""
	estadd local cumsum_b "`cumsum_b'"
	estadd local cumsum_V "`cumsum_V'"
	estadd local longrun_b "`longrun_b'"
	estadd local longrun_V "`longrun_V'" */
end 


program compute_cumsum, rclass
	syntax, coefficients(str)
	lincomest `coefficients'
	mat b = e(b)
	mat V = e(V)
	local b_digits = round(b[1,1], 0.0001)
	local se_digits = round(V[1,1]^.5, 0.0001)
	if abs(b[1,1]/(V[1,1]^.5)) > 2.576 {
		local star = "\sym{***}"
	}
	else if abs(b[1,1]/(V[1,1]^.5)) > 1.96 {
		local star = "\sym{**}"
	}
	else if abs(b[1,1]/(V[1,1]^.5)) > 1.645 {
		local star = "\sym{*}"
	}
	else {
		local star = ""
	}

	local cumsum_b = "0`b_digits'`star'"
	local cumsum_V = "(0`se_digits')"

	return local cumsum_b `cumsum_b'
	return local cumsum_V `cumsum_V'
end

program compute_longrun, rclass
	syntax, depvar(str)
	
	nlcom (_b[D1.ln_mw] + _b[LD.ln_mw])/(1 - _b[LD.`depvar'])
	mat b = r(b)
	mat V = r(V)
	local b_digits = round(b[1,1], 0.0001)
	local se_digits = round(V[1,1]^.5, 0.0001)
	if abs(b[1,1]/(V[1,1]^.5)) > 2.576 {
		local star = "\sym{***}"
	}
	else if abs(b[1,1]/(V[1,1]^.5)) > 1.96 {
		local star = "\sym{**}"
	}
	else if abs(b[1,1]/(V[1,1]^.5)) > 1.645 {
		local star = "\sym{*}"
	}
	else {
		local star = ""
	}

	local longrun_b = "0`b_digits'`star'"
	local longrun_V = "(0`se_digits')"

	return local longrun_b `longrun_b'
	return local longrun_V `longrun_V'
end

program comment_table_control
	syntax, emp(str) estab(str) wage(str) housing(str)

	estadd local ctrl_emp   "`emp'"
	estadd local ctrl_estab "`estab'"
	estadd local ctrl_wage  "`wage'"
	estadd local ctrl_building "`housing'"
end

*program comment_table_treatindicator
*	syntax, treat_dir(str) treat_ind(str)
*
*	estadd local trdir   "`treat_dir'"
*	estadd local trind "`treat_ind'"
*end

main 