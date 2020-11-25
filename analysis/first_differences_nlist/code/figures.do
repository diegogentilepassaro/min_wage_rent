clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../temp"
	local outstub "../output"

	use "`instub'/fd_rent_panel.dta", clear

	plot_dynamic_placebo, depvar(ln_med_rent_psqft_sfcc) placebovar(ln_n_listings_sfcc) ///
						absorb(year_month zipcode) cluster(statefips)



end


program plot_dynamic_placebo 
	syntax, depvar(str) placebovar(str) absorb(str) cluster(str) [w(int 5) t_plot(real 1.645)]

	define_controls estcount avgwwage
	local emp_ctrls "`r(emp_ctrls)'"
	local estcount_ctrls "`r(estcount_ctrls)'"
	local avgwwage_ctrls "`r(avgwwage_ctrls)'"

	local controls `"`emp_ctrls' `estcount_ctrls' `avgwwage_ctrls'"'

	eststo clear
	eststo: reghdfe D.`placebovar' L(-`w'/`w').D.ln_mw `controls', ///
		absorb(`absorb') ///
		vce(cluster `cluster') nocons

	preserve
		coefplot, vertical base gen
		local winspan = 2*`w' + 1
		keep if _n<=`winspan'
		keep __at __b __se
		rename (__at __b __se) (at b_placebo1 se_placebo1)
		keep if !missing(at)

		gen b_placebo1_lb = b_placebo1 - `t_plot'*se_placebo1
		gen b_placebo1_ub = b_placebo1 + `t_plot'*se_placebo1

		sort at 

		make_plot_xlabels, w(`w')

		twoway (connected b_placebo1 at, mc(edkblue) lc(edkblue) lw(thin)) (rcap b_placebo1_lb b_placebo1_ub at, lc(edkblue) lp(dash) lw(vthin)), /// 
			graphregion(color(white)) bgcolor(white) ///
			xlabel(`r(xlab)', labsize(vsmall)) xtitle(" ") ///
			ytitle("Coefficient") ylabel(-0.3(0.1).5, grid labsize(small))	///
			yline(0, lcol(black)) ///
			legend(off)
		graph export "../output/fd_placebo.png", replace
		graph export "../output/fd_placebo.eps", replace
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
