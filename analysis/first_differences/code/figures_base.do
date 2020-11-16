clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../temp"
	local outstub "../output"

	use "`instub'/fd_rent_panel.dta", clear

	build_coeff_plot, depvar(ln_med_rent_psqft_sfcc) absorb(year_month) ///
		cluster(statefips)
	graph export "`outstub'/fd_models.png", replace
	graph export "`outstub'/fd_models.eps", replace

	use "`instub'/fd_rent_panel.dta", clear

	build_coeff_plot_controls, depvar(ln_med_rent_psqft_sfcc) absorb(year_month) ///
		cluster(statefips)
	graph export "../output/fd_models_control.png", replace
	graph export "../output/fd_models_control.eps", replace
end

program build_coeff_plot
	syntax, depvar(str) absorb(str) cluster(str) [w(int 5) t_plot(real 1.645) offset(real 0.09)]

	eststo clear
	reghdfe D.`depvar' D.ln_mw,	absorb(`absorb') vce(cluster `cluster') nocons

	scalar static_effect = _b[D.ln_mw]
	scalar static_effect_se = _se[D.ln_mw]

	define_controls estcount avgwwage
	local emp_ctrls "`r(emp_ctrls)'"
	local estcount_ctrls "`r(estcount_ctrls)'"
	local avgwwage_ctrls "`r(avgwwage_ctrls)'"

	qui reghdfe D.`depvar' L(-`w'/`w').D.ln_mw, absorb(`absorb') vce(cluster `cluster') nocons
	
	preserve
		coefplot, vertical base gen
		keep __at __b __se
		rename (__at __b __se) (at b_full se_full)
		
		keep if !missing(at)

		gen b_full_lb = b_full - `t_plot'*se_full
		gen b_full_ub = b_full + `t_plot'*se_full

		gen static_path = . 
		replace static_path = scalar(static_effect) if at > `w'

		save "../temp/plot_coeffs.dta", replace
	restore

	qui reghdfe D.`depvar' L(0/`w').D.ln_mw, absorb(`absorb') vce(cluster `cluster') nocons
	
	coefplot, vertical base gen
	keep __at __b __se
	rename (__at __b __se) (at b_lags se_lags)
	tset at

	keep if !missing(at)

	gen b_lags_lb = b_lags - 1.645*se_lags
	gen b_lags_ub = b_lags + 1.645*se_lags

	gen cumsum_b_lags = b_lags[1]
	replace cumsum_b_lags = cumsum_b_lags[_n-1] + b_lags[_n] if _n > 1

	replace at = at + `w'
		
	merge 1:1 at using "../temp/plot_coeffs.dta", nogen
	sort at

	gen at_full = at - `offset'                  // To prevent lines from overlapping perfectly
	gen at_lags = at + `offset'
	replace at_full = at if _n <= `w'
	replace at_lags = at if _n <= `w'
	replace cumsum_b_lags = . if at < `w' - 1

	// Figure
	make_plot_xlabels, w(`w')

	twoway 	(scatter b_full at_full, mcol(navy)) ///
				(rcap b_full_lb b_full_ub at_full, col(navy) lw(vthin)) ///
			(scatter b_lags at_lags, mcol(maroon)) ///
				(rcap b_lags_lb b_lags_ub at_lags, col(maroon) lw(vthin)) ///
			(line static_path at, lcol(gs4) lpat(dash)) ///
			(line cumsum_b_lags at, lcol(maroon) lpat(dash)), ///
		yline(0, lcol(black)) ///
		xlabel(`r(xlab)', labsize(small)) xtitle("Leads and lags of difference in log MW") ///
		ylabel(-0.06(0.02).08, grid labsize(small)) ytitle("Coefficient") ///
		legend(order(1 "Full dynamic model" 3 "Distributed lags model" ///
			5 "Effects path static model" 6 "Effects path distributed lags model") size(small)) ///
		graphregion(color(white)) bgcolor(white)
end

program build_coeff_plot_controls
	syntax, depvar(str) absorb(str) cluster(str) [w(int 5) t_plot(real 1.645) offset(real 0.17)]

	eststo clear

	define_controls
	local emp_ctrls "`r(emp_ctrls)'"
	local estab_ctrls "`r(estcount_ctrls)'"
	local wage_ctrls "`r(avgwwage_ctrls)'"

	reghdfe D.`depvar' L(-`w'/`w').D.ln_mw, absorb(`absorb') vce(cluster `cluster') nocons
	store_dynamic_coeffs, model(base) w(`w') t_plot(`t_plot')

	foreach name in emp estab wage {
		reghdfe D.`depvar' L(-`w'/`w').D.ln_mw D.(``name'_ctrls'), absorb(`absorb') vce(cluster `cluster') nocons
		store_dynamic_coeffs, model(`name') w(`w') t_plot(`t_plot')
	}
			
	reghdfe D.`depvar' L(-`w'/`w').D.ln_mw D.(`emp_ctrls') D.(`estab_ctrls') D.(`wage_ctrls'), ///
		absorb(`absorb') vce(cluster `cluster') nocons

	coefplot, vertical base gen
	local winspan = 2*`w' + 1
	keep if _n <= `winspan'
	keep __at __b __se
	rename (__at __b __se) (at b_all se_all)
	keep if !missing(at)

	gen b_all_lb = b_all - `t_plot'*se_all
	gen b_all_ub = b_all + `t_plot'*se_all

	merge 1:1 at using "../temp/plot_coeffs_base.dta", nogen
	merge 1:1 at using "../temp/plot_coeffs_emp.dta", nogen
	merge 1:1 at using "../temp/plot_coeffs_estab.dta", nogen
	merge 1:1 at using "../temp/plot_coeffs_wage.dta", nogen

	sort at
	g at_emp   = at - 2*`offset'
	g at_estab = at - `offset'
	g at_wage  = at + `offset'
	g at_all = at + 2*`offset'

	make_plot_xlabels, w(`w')

	twoway (scatter b_base at, mcol(navy))          (rcap b_base_lb b_base_ub at, lc(navy) lw(vthin)) ///
		   (scatter b_emp at_emp, mc(maroon))       (rcap b_emp_lb b_emp_ub at_emp, lc(maroon) lw(vthin)) ///
		   (scatter b_estab at_estab, mc(lavender)) (rcap b_estab_lb b_estab_ub at_est, lc(lavender) lw(vthin)) ///
		   (scatter b_wage at_wage, mc(dkorange))   (rcap b_wage_lb b_wage_ub at_wage, lc(dkorange) lw(vthin)) ///
		   (scatter b_all at_all, mc(gs10))         (rcap b_all_lb b_all_ub at_all, lc(gs10) lw(vthin)), /// 
		yline(0, lcol(black)) ///
		graphregion(color(white)) bgcolor(white) ///
		xlabel(`r(xlab)', labsize(vsmall)) xtitle("Leads and lags of difference in log MW") ///
		ytitle("Dynamic coefficients") ylabel(-0.06(0.02).06, grid)	///
		legend(order(1 "Baseline" 3 "Employment" ///
			5 "Establishment" 7 "Wage" 9 "Building") size(small) rows(1))
end

program store_dynamic_coeffs
	syntax, model(str) w(int) t_plot(real)
	preserve
		coefplot, vertical base gen
		local wspan = 2*`w' + 1
		keep if _n <= `wspan'
		keep __at __b __se
		rename (__at __b __se) (at b_`model' se_`model')
	
		keep if !missing(at)

		gen b_`model'_lb = b_`model' - `t_plot'*se_`model'
		gen b_`model'_ub = b_`model' + `t_plot'*se_`model'
	
		save "../temp/plot_coeffs_`model'.dta", replace
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
