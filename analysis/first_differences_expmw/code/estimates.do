clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000

program main
	local instub "../../../drive/derived_large/estimation_samples"
	local outstub "../output"

	use "`instub'/baseline_zipcode_months.dta", clear
	
	destring zipcode, gen(zipode_num)
	xtset zipode_num year_month

	make_results_labels, w(5)
	local estlabels_dyn "`r(estlabels_dyn)'"
	local estlabels_static "`r(estlabels_static)'"

	run_models, depvar(ln_med_rent_var) absorb(year_month) ///
		cluster(statefips)
	esttab using "`outstub'/expmw_static_results.tex", replace compress se substitute(\_ _) ///
		keep(D.ln_mw D.exp_ln_mw) b(%9.4f) se(%9.4f) ///
		coeflabels(D.ln_mw "$\Delta \ln \underline{w}_{ict}$" ///
		D.exp_ln_mw "$\Delta \ln \underline{w}_{ict}^{\text{exp}}$") ///
		stats(space ctrl_wage ctrl_emp ctrl_estab p_value_F r2 N, ///
		fmt(%s1 %s3 %s3 %s3 %9.3f %9.3f %9.0gc) ///
		labels("\vspace{-2mm}" "Wage controls" "Employment controls" ///
		"Establishment-count controls" "P-value equality" "R-squared" "Observations")) ///
		mgroups("$\Delta \ln \underline{w}_{ict}^{\text{exp}}$" "$\Delta \ln y_{ict}$", ///
		pattern(1 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span ///
		erepeat(\cmidrule(lr){@span})) nomtitles star(* 0.10 ** 0.05 *** 0.01) nonote
end 

program run_models 
	syntax, depvar(str) absorb(str) cluster(str) [w(int 5)]

	eststo clear
	define_controls
	local controls "`r(economic_controls)'"

	* exp_mw vs actual_mw
	eststo: reghdfe D.exp_ln_mw D.ln_mw D.(`controls') if !missing(D.ln_med_rent_var), ///
		absorb(`absorb') vce(cluster `cluster') nocons
	comment_table_control, emp("Yes") estab("Yes") wage("Yes") housing("No")
	estadd local space ""

	*baseline

	eststo: reghdfe D.`depvar' D.ln_mw D.(`controls'), ///
		absorb(`absorb') vce(cluster `cluster') nocons
	comment_table_control, emp("Yes") estab("Yes") wage("Yes") housing("No")
	estadd local space ""

	*experienced

	eststo: reghdfe D.`depvar' D.exp_ln_mw D.(`controls'), ///
		absorb(`absorb') vce(cluster `cluster') nocons
	comment_table_control, emp("Yes") estab("Yes") wage("Yes") housing("No")
	estadd local space ""

	*both 
	eststo: qui reghdfe D.`depvar' D.ln_mw D.exp_ln_mw D.(`controls'), ///
		absorb(`absorb') vce(cluster `cluster') nocons
	comment_table_control, emp("Yes") estab("Yes") wage("Yes") housing("No")
	estadd local space ""
	
	
	file open myfile using "../output/test_coefficients_static.log", write replace
	file write myfile "Static model when including both actual and exp MW" _n

	test (D.ln_mw = D.exp_ln_mw)
	estadd scalar p_value_F = r(p)
	file write myfile "P-value static coefficients are the same: `r(p)'" _n
	
	file close myfile
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

main 
