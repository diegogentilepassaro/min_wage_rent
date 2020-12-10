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


	static_dynamic_comp, depvar(ln_med_rent_psqft_sfcc) absorb(year_month) ///
		cluster(statefips) add_unbal(yes)
	
	esttab using "`outstub'/static_dynamic_comptable.tex", replace compress se substitute(\_ _) ///
		keep(D.ln_mw) b(%9.4f) se(%9.4f) coeflabels(D.ln_mw "Static Effect") ///
		stats(space cumsum_b cumsum_V longrun_b longrun_V space ctrl_wage ctrl_emp ctrl_estab N,  ///
		fmt(%s1 %s7 %s7 %s7 %s7 %s1 %s3 %s3 %s3 %9.0gc) ///
		labels("\vspace{-2mm}" "Cumulative effect" " " "Long-run effect" " " "\hline" ///
			"Wage controls" "Employment controls" "Establishment-count controls"  ///
			"Observations (static model)")) ///
		mtitles("Baseline" "Reweighted" "Unbalanced") ///
		star(* 0.10 ** 0.05 *** 0.01) nonote
end 


program static_dynamic_comp 
	syntax, depvar(str) absorb(str) cluster(str) [w(int 5) t_plot(real 1.645) add_unbal(str)] 

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
	reghdfe D.`depvar' L(0/`w').D.ln_mw D.(`controls'), ///
		absorb(`absorb') vce(cluster `cluster') nocons	
	compute_cumsum, coefficients(`lincomest_coeffs')

	local cumsum_b "`r(cumsum_b)'"
	local cumsum_V "`r(cumsum_V)'"

	ivreghdfe D.`depvar' L(0/`w').D.ln_mw (L.D.`depvar' = L2.D.`depvar') D.(`controls'), ///
		absorb(`absorb') cluster(`cluster') nocons
	compute_longrun, depvar(`depvar')

	local longrun_b "`r(longrun_b)'"
	local longrun_V "`r(longrun_V)'"
	
	eststo: reghdfe D.`depvar' D.ln_mw D.(`controls'), ///
		absorb(`absorb') vce(cluster `cluster') nocons
	comment_table_control, emp("Yes") estab("Yes") wage("Yes") housing("No")
	estadd local space ""

	estadd local cumsum_b "`cumsum_b'"
	estadd local cumsum_V "`cumsum_V'"
	estadd local longrun_b "`longrun_b'"
	estadd local longrun_V "`longrun_V'"

	*weighted 
	reghdfe D.`depvar' L(0/`w').D.ln_mw D.(`controls') [pw = wgt_cbsa100], ///
		absorb(`absorb') vce(cluster `cluster') nocons	

	compute_cumsum, coefficients(`lincomest_coeffs')

	local cumsum_b "`r(cumsum_b)'"
	local cumsum_V "`r(cumsum_V)'"

	ivreghdfe D.`depvar' L(0/`w').D.ln_mw (L.D.`depvar' = L2.D.`depvar') D.(`controls') [pw = wgt_cbsa100], ///
		absorb(`absorb') cluster(`cluster') nocons
	compute_longrun, depvar(`depvar')

	local longrun_b "`r(longrun_b)'"
	local longrun_V "`r(longrun_V)'"

	eststo: reghdfe D.`depvar' D.ln_mw D.(`controls') [pw = wgt_cbsa100], ///
		absorb(`absorb') vce(cluster `cluster') nocons
	comment_table_control, emp("Yes") estab("Yes") wage("Yes") housing("No")
	estadd local space ""

	estadd local cumsum_b "`cumsum_b'"
	estadd local cumsum_V "`cumsum_V'"
	estadd local longrun_b "`longrun_b'"
	estadd local longrun_V "`longrun_V'"

	if "`add_unbal'"=="yes" {
		use "../../first_differences_unbal/temp/unbal_fd_rent_panel.dta", clear

		*Unbalanced
		qui reghdfe D.`depvar' L(0/`w').D.ln_mw D.(`controls'), absorb(`absorb' entry_sfcc#year_month) vce(cluster `cluster') nocons	

		compute_cumsum, coefficients(`lincomest_coeffs')

		local cumsum_b "`r(cumsum_b)'"
		local cumsum_V "`r(cumsum_V)'"

		ivreghdfe D.`depvar' L(0/`w').D.ln_mw (L.D.`depvar' = L2.D.`depvar') D.(`controls'), ///
			absorb(`absorb') cluster (`cluster') nocons
		compute_longrun, depvar(`depvar')

		local longrun_b "`r(longrun_b)'"
		local longrun_V "`r(longrun_V)'"

		eststo: qui reghdfe D.`depvar' D.ln_mw D.(`controls'), ///
			absorb(`absorb' entry_sfcc#year_month) vce(cluster `cluster') nocons
		comment_table_control, emp("Yes") estab("Yes") wage("Yes") housing("No")
		estadd local space ""

		estadd local cumsum_b "`cumsum_b'"
		estadd local cumsum_V "`cumsum_V'"
		estadd local longrun_b "`longrun_b'"
		estadd local longrun_V "`longrun_V'"
	}
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