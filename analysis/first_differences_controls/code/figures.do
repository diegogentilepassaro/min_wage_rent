clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main 
	local instub "../../../derived/county_quarter/output"
	local outstub "../output"

	use `instub'/qcew_controls_countyquarter_panel.dta, clear

	local industries "info bizserv fin const eduhe leis manu natres transp"
/* 	local depvarlist ""
	foreach ind in `industries' {
		local depvarlist `"`depvarlist' ln_emp_`ind' ln_wwage_`ind' ln_est_`ind'"'
	}
 */

	foreach var in `industries' {
		plot_dynamic, ind(`var') treatvar(ln_mw) absorb(quarter) cluster(statefips) outstub(`outstub') w(3)
	}

end







program plot_dynamic
	syntax, ind(str) treatvar(str) absorb(str) cluster(str) outstub(str) [w(int 5) t_plot(real 1.645) offset(real 0.09)]

	local depvar_emp "d_ln_emp_`ind'"
	reghdfe `depvar_emp' L(-`w'/`w').D.`treatvar' avg_d_ln_est_tot avg_d_ln_wwage_tot d_ln_emp_tot, ///
		absorb(`absorb')        ///
		vce(cluster `cluster') nocons

	preserve
		coefplot, vertical base gen keep(*.`treatvar')
		keep __at __b __se
		rename (__at __b __se) (at b_emp se_emp)
		
		keep if !missing(at)

		gen b_emp_lb = b_emp - `t_plot'*se_emp
		gen b_emp_ub = b_emp + `t_plot'*se_emp
		save ../temp/coeffs_emp.dta, replace 
	restore

	local depvar_wage "avg_d_ln_wwage_`ind'"
	reghdfe `depvar_wage' L(-`w'/`w').D.`treatvar' avg_d_ln_est_tot avg_d_ln_wwage_tot d_ln_emp_tot, ///
		absorb(`absorb')        ///
		vce(cluster `cluster') nocons

	preserve
		coefplot, vertical base gen keep(*.`treatvar')
		keep __at __b __se
		rename (__at __b __se) (at b_wage se_wage)
		
		keep if !missing(at)

		gen b_wage_lb = b_wage - `t_plot'*se_wage
		gen b_wage_ub = b_wage + `t_plot'*se_wage
		save ../temp/coeffs_wage.dta, replace 
	restore


	local depvar_est "avg_d_ln_est_`ind'"
	reghdfe `depvar_est' L(-`w'/`w').D.`treatvar' d_ln_emp_tot avg_d_ln_wwage_tot avg_d_ln_est_tot, ///
		absorb(`absorb')        ///
		vce(cluster `cluster') nocons

	preserve
		coefplot, vertical base gen keep(*.`treatvar')
		keep __at __b __se
		rename (__at __b __se) (at b_est se_est)
		
		keep if !missing(at)

		gen b_est_lb = b_est - `t_plot'*se_est
		gen b_est_ub = b_est + `t_plot'*se_est
		save ../temp/coeffs_est.dta, replace 

		merge 1:1 at using ../temp/coeffs_emp.dta, nogen assert(1 2 3) keep(1 3)
		merge 1:1 at using ../temp/coeffs_wage.dta, nogen assert(1 2 3) keep(1 3)

	make_plot_xlabels, w(`w')
	gen at_emp = at - `offset'                 // To prevent lines from overlapping perfectly
	gen at_wage = at
	gen at_est = at + `offset'

	twoway 	(connect b_emp at_emp, col(navy)) ///
				(rcap b_emp_lb b_emp_ub at_emp, col(navy) lw(vthin)) ///
			(connect b_wage at_wage, col(maroon) m(diamond)) ///
				(rcap b_wage_lb b_wage_ub at_wage, col(maroon) lw(vthin)) ///
			(connect b_est at_est, col(eltgreen) m(triangle)) ///
				(rcap b_est_lb b_est_ub at_est, col(eltgreen) lw(vthin)), ///		
		yline(0, lcol(black)) ///
		xlabel(`r(xlab)', labsize(small)) xtitle(" ") ///
		ylabel(-0.3(0.1)0.4, grid labsize(small)) ytitle("Coefficient") ///
		legend(order(1 "Employment" 3 "Weekly Wage" 5 "Establishment count") rows(1) size(small)) ///
		graphregion(color(white)) bgcolor(white)
	graph export "`outstub'/fd_models_`ind'_w`w'.eps", replace		
	restore


end 

program make_plot_xlabels, rclass 
	syntax, w(int)

	local xlab ""
	forval lead = 1/`w' {
		local leadlab = `lead' - `w' - 1
		local xlab `"`xlab' `lead' "`leadlab'""'
	}
	local zero = `w' + 1
	local xlab `"`xlab' `zero' "0""'
	forval lag = 1/`w' {
		local coeflag = `zero' + `lag'
		local xlab `"`xlab' `coeflag' "`lag'""'
	}

	return local xlab `xlab'
end

main 
