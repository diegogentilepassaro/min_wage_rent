clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main 
	local instub "../../../derived/county_quarter/output"
	local outstub "../output"

	local industries "info bizserv fin"

	use `instub'/qcew_controls_countyquarter_panel.dta, clear
	
	foreach var in `industries' {
		plot_dynamic, ind(`var') treatvar(ln_mw) absorb(quarter) cluster(statefips) instub(`instub') outstub(`outstub') w(3)
	}
end

program plot_dynamic
	syntax, ind(str) treatvar(str) absorb(str) cluster(str) instub(str) outstub(str) [w(int 5) t_plot(real 1.645) offset(real 0.25)]

	local depvar_wage "avg_d_ln_wwage_`ind'"
	reghdfe `depvar_wage' L(-`w'/`w').D.`treatvar', ///
		absorb(`absorb') vce(cluster `cluster') nocons

	preserve
		coefplot, vertical base gen keep(*.`treatvar')
		keep __at __b __se
		rename (__at __b __se) (at b_wage se_wage)
		
		keep if !missing(at)
		replace at = (at*3) - 2

		gen b_wage_lb = b_wage - `t_plot'*se_wage
		gen b_wage_ub = b_wage + `t_plot'*se_wage
		save ../temp/coeffs_wage.dta, replace 
	restore


	local depvar_est "avg_d_ln_est_`ind'"
	reghdfe `depvar_est' L(-`w'/`w').D.`treatvar' , ///
		absorb(`absorb')        ///
		vce(cluster `cluster') nocons

	preserve
		coefplot, vertical base gen keep(*.`treatvar')
		keep __at __b __se
		rename (__at __b __se) (at b_est se_est)
		
		keep if !missing(at)
		replace at = (at*3) - 2


		gen b_est_lb = b_est - `t_plot'*se_est
		gen b_est_ub = b_est + `t_plot'*se_est
		save ../temp/coeffs_est.dta, replace 
	restore

	preserve
		use `instub'/qcew_controls_countymonth.dta, clear
		local mw = `w'*3
		local depvar_emp "d_ln_emp_`ind'"
		reghdfe `depvar_emp' L(-`mw'/`mw').D.`treatvar', ///
			absorb(year_month)        ///
			vce(cluster `cluster') nocons

		coefplot, vertical base gen keep(*.`treatvar')
		keep __at __b __se
		rename (__at __b __se) (at b_emp se_emp)
		
		keep if !missing(at)

		gen b_emp_lb = b_emp - `t_plot'*se_emp
		gen b_emp_ub = b_emp + `t_plot'*se_emp
		save ../temp/coeffs_emp.dta, replace 

		merge 1:1 at using ../temp/coeffs_est.dta, nogen assert(1 2 3) keep(1 3)
		merge 1:1 at using ../temp/coeffs_wage.dta, nogen assert(1 2 3) keep(1 3)
		tset at 
		local zero = `mw' + 1
		foreach var in b_est b_est_lb b_est_ub b_wage b_wage_lb b_wage_ub {
			replace `var' = F.`var' if at > `zero'
		}
		g at_inv = - at 
		tset at_inv
		foreach var in b_est b_est_lb b_est_ub b_wage b_wage_lb b_wage_ub {
			replace `var' = F.`var' if at_inv > - `zero'
		}		
		drop at_inv
		sort at 
		tset at

		make_plot_xlabels, w(`mw')
		gen at_wage = at - `offset'
		gen at_emp = at                  
		gen at_est = at + `offset'

		twoway 	(connect b_emp at_emp, col(eltgreen)) ///
					(rcap b_emp_lb b_emp_ub at_emp, col(eltgreen) lw(vthin)) ///
				(connect b_wage at_wage, col(maroon) m(diamond)) ///
					(rcap b_wage_lb b_wage_ub at_wage, col(maroon) lw(vthin)) ///
				(connect b_est at_est, col(navy) m(triangle)) ///
					(rcap b_est_lb b_est_ub at_est, col(navy) lw(vthin)), ///		
			yline(0, lcol(black)) ///
			xlabel(`r(xlab)', labsize(small)) xtitle(" ") ///
			ylabel(-0.2(0.1)0.2, grid labsize(small)) ytitle("Coefficient") ///
			legend(order(1 "Employment" 3 "Weekly Wage" 5 "Establishment count") rows(1) size(small)) ///
			graphregion(color(white)) bgcolor(white)
		graph export "`outstub'/fd_models_`ind'_w`w'.eps", replace
		graph export "`outstub'/fd_models_`ind'_w`w'.png", replace	
	restore
end 

program make_plot_xlabels, rclass 
	syntax, w(int)
/* 
	local qw = `w' / 3
	local xlab ""

	local this_qw = 1
	forval lead = 1/`w' {
		local leadlab = `lead' - `w' - 1
		local test_qw =  (`this_qw'*3)-2
		if `test_qw'!=`lead'{
			local xlab `"`xlab' `lead' "`leadlab'""'
		}
		else if `test_qw'==`lead' {
			local leadlab2 = `this_qw' - `qw' - 1
			local xlab `"`xlab' `lead' `" "`leadlab'" "(`leadlab2')""' "'
			local this_qw = `this_qw' + 1
		}
	}
	local zero = `w' + 1
	local xlab `"`xlab' `zero' "0" "(0)""'
	di "`xlab'"
	
	local lag2 = 1
	forval lag = 1/`w' {
		local coeflag = `zero' + `lag'
		local test_qw = (`this_qw'*3)-2
		if `test_qw'!=`coeflag' {
			local xlab `"`xlab' `coeflag' "`lag'""'
		}
		else if `test_qw'==`coeflag' {
			local xlab `"`xlab' `coeflag' `""`lag'" "(`lag2')""'"'
			local lag2 = `lag' + 1
			local this_qw = `this_qw' + 1			
		}
	} */

	if `w'==9 {
		local xlab `"       1 "-9" 2 `""-8" "(-3)""' 3 "-7" 4 "-6" 5 `""-5" "(-2)""'"'
		local xlab `"`xlab' 6 "-4" 7 "-3" 8 `""-2" "(-1)""' 9 "-1" 10 `""0" "(0)""'"'
		local xlab `"`xlab' 11 "1" 12 `""2" "(1)""' 13 "3" 14 "4" 15 `""5" "(2)""'"'
		local xlab `"`xlab' 16 "6" 17 "7" 18 `""8" "(3)""' 19 "9"                "'
	}
	
	

	return local xlab `xlab'
end

main 
