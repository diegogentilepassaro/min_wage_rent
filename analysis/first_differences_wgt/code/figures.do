clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../temp"
	local outstub "../output"

	use "`instub'/fd_rent_panel.dta", clear

	build_coeff_plot_comp, depvar(ln_med_rent_psqft_sfcc) absorb(year_month) ///
		cluster(statefips)

end



program build_coeff_plot_comp
	syntax, depvar(str) absorb(str) cluster(str) [w(int 5) t_plot(real 1.645) offset(real 0.09)]

	define_controls estcount avgwwage
	local emp_ctrls "`r(emp_ctrls)'"
	local estcount_ctrls "`r(estcount_ctrls)'"
	local avgwwage_ctrls "`r(avgwwage_ctrls)'"

	local controls `"`emp_ctrls' `estcount_ctrls' `avgwwage_ctrls'"'

	reghdfe D.`depvar' L(-`w'/`w').D.ln_mw D.(`controls'), absorb(`absorb') vce(cluster `cluster') nocons
	
	preserve
		coefplot, vertical base gen
		keep __at __b __se
		rename (__at __b __se) (at b_full se_full)
		
		local winspan = 2*`w' + 1
		keep if _n<=`winspan'
		keep if !missing(at)

		gen b_full_lb = b_full - `t_plot'*se_full
		gen b_full_ub = b_full + `t_plot'*se_full

		save "../temp/plot_coeffs_base.dta", replace
	restore


	reghdfe D.`depvar' L(-`w'/`w').D.ln_mw D.(`controls') [pw = wgt_cbsa100], ///
	absorb(`absorb') vce(cluster `cluster') nocons

				
	preserve
		coefplot, vertical base gen
		keep __at __b __se
		rename (__at __b __se) (at b_wgt se_wgt)
		tset at

		local winspan = 2*`w' + 1
		keep if _n<=`winspan'
		keep if !missing(at)

		gen b_wgt_lb = b_wgt - `t_plot'*se_wgt
		gen b_wgt_ub = b_wgt + `t_plot'*se_wgt
			
		gen cumsum_b_wgt = b_wgt[1]
		replace cumsum_b_wgt = cumsum_b_wgt[_n-1] + b_wgt[_n] if _n > 1
		merge 1:1 at using "../temp/plot_coeffs_base.dta", nogen assert(1 2 3)

		sort at
			
		// To prevent lines from overlapping perfectly
		gen at_full = at - `offset'
		gen at_base = at + `offset'
		//replace at_full = at if _n <= `w'
		//replace at_base = at if _n <= `w'

		//replace cumsum_b_lags = cumsum_b_lags - 0.00007 if _n <= `w'
		//replace static_path = static_path + 0.00007 if _n <= `w'

		// Figure
		make_plot_xlabels, w(`w')
		local xlab "`r(xlab)'"

		twoway (scatter b_full at_base, mcol(gs10)) (rcap b_full_lb b_full_ub at_base, lcol(gs10) lw(thin)) ///
			   (scatter b_wgt at_full, mcol(navy)) (rcap b_wgt_lb b_wgt_ub at_full, col(navy) lw(thin)), ///
			   yline(0, lcol(black)) ///
			   xlabel(`xlab', labsize(small)) xtitle("") ///
			   ylabel(-0.06(0.02).08, grid labsize(small)) ytitle("Coefficient") ///
			   legend(order(1 "Baseline dynamic model" 3 "Reweighted dynamic model") size(vsmall)) ///
			   graphregion(color(white)) bgcolor(white)
			   STOP 
		graph export "../output/fd_model_comparison_wgt.png", replace
		graph export "../output/fd_model_comparison_wgt.eps", replace

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
