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

	foreach var in walall_29y_lowinc_zsh halall_29y_lowinc_zsh walall_29y_lowinc_ssh halall_29y_lowinc_ssh {
		plot_static_heterogeneity, depvar(ln_med_rent_psqft_sfcc) absorb(year_month zipcode) ///
				het_var(`var'_st_qtl) cluster(statefips) outstub(`outstub')		

		plot_static_heterogeneity, depvar(ln_med_rent_psqft_sfcc) absorb(year_month zipcode) ///
				het_var(`var'_nat_qtl) cluster(statefips) outstub(`outstub')		

	}	


end 


program build_coeff_plot_comp
	syntax, depvar(str) absorb(str) cluster(str) [w(int 5) t_plot(real 1.645) offset(real 0.09)]

	define_controls estcount avgwwage
	local emp_ctrls "`r(emp_ctrls)'"
	local estcount_ctrls "`r(estcount_ctrls)'"
	local avgwwage_ctrls "`r(avgwwage_ctrls)'"

	local controls `"`emp_ctrls' `estcount_ctrls' `avgwwage_ctrls'"'

	*cumulative base
	preserve 
	qui reghdfe D.`depvar' L(-`w'/`w').D.ln_mw D.(`controls'), absorb(`absorb') vce(cluster `cluster') nocons
	local w_halfspan = `w' + 1
	matrix CUMBASE = J(`w_halfspan', 5, .)
	matrix colname CUMBASE = "at" "cumsum_base_b" "cumsum_base_se" "cumsum_base_lb" "cumsum_base_ub"
	local firstcoeff = "D1.ln_mw"
	local cumcoeff = `"`firstcoeff'"'
	matrix 	CUMBASE[1, 1] = 0
	lincomest `firstcoeff'
	mat b = e(b)
	mat V = e(V)
	matrix CUMBASE[1,2] = b[1,1]
	matrix CUMBASE[1,3] = V[1,1]^.5
	matrix CUMBASE[1,4] = b[1, 1] - `t_plot'*V[1, 1]^.5
	matrix CUMBASE[1,5] = b[1, 1] + `t_plot'*V[1, 1]^.5
	forval i = 1/`w' {
		qui reghdfe D.`depvar' L(-`w'/`w').D.ln_mw D.(`controls'), absorb(`absorb') vce(cluster `cluster') nocons
		local at = `i' + 1
		local cumcoeff = `"`cumcoeff' + L`i'D.ln_mw"'
		lincomest `cumcoeff'
		mat b = e(b)
		mat V = e(V)
		matrix CUMBASE[`at',1] = `i'
		matrix CUMBASE[`at',2] = b[1,1]
		matrix CUMBASE[`at',3] = V[1,1]^.5
		matrix CUMBASE[`at',4] = b[1, 1] - `t_plot'*V[1, 1]^.5
		matrix CUMBASE[`at',5] = b[1, 1] + `t_plot'*V[1, 1]^.5
	}
	svmat double CUMBASE, name(col)	
	keep at cumsum_*
	drop if missing(at)
	replace at = at + `w' + 1
	save "../temp/cumsum_base.dta", replace 
	restore

	*regular base
	qui reghdfe D.`depvar' L(-`w'/`w').D.ln_mw D.(`controls'), absorb(`absorb') vce(cluster `cluster') nocons
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

	*cumsum experienced MW
	preserve 
	qui reghdfe D.`depvar' L(-`w'/`w').D.ln_expmw D.(`controls'), absorb(`absorb') vce(cluster `cluster') nocons
	local w_halfspan = `w' + 1
	matrix CUMBASE = J(`w_halfspan', 5, .)
	matrix colname CUMBASE = "at" "cumsum_exp_b" "cumsum_exp_se" "cumsum_exp_lb" "cumsum_exp_ub"
	local firstcoeff = "D1.ln_expmw"
	local cumcoeff = `"`firstcoeff'"'
	matrix 	CUMBASE[1, 1] = 0
	lincomest `firstcoeff'
	mat b = e(b)
	mat V = e(V)
	matrix CUMBASE[1,2] = b[1,1]
	matrix CUMBASE[1,3] = V[1,1]^.5
	matrix CUMBASE[1,4] = b[1, 1] - `t_plot'*V[1, 1]^.5
	matrix CUMBASE[1,5] = b[1, 1] + `t_plot'*V[1, 1]^.5
	forval i = 1/`w' {
		qui reghdfe D.`depvar' L(-`w'/`w').D.ln_expmw D.(`controls'), absorb(`absorb') vce(cluster `cluster') nocons
		local at = `i' + 1
		local cumcoeff = `"`cumcoeff' + L`i'D.ln_expmw"'
		lincomest `cumcoeff'
		mat b = e(b)
		mat V = e(V)
		matrix CUMBASE[`at',1] = `i'
		matrix CUMBASE[`at',2] = b[1,1]
		matrix CUMBASE[`at',3] = V[1,1]^.5
		matrix CUMBASE[`at',4] = b[1, 1] - `t_plot'*V[1, 1]^.5
		matrix CUMBASE[`at',5] = b[1, 1] + `t_plot'*V[1, 1]^.5
	}
	svmat double CUMBASE, name(col)	
	keep at cumsum_*
	drop if missing(at)
	replace at = at + `w' + 1
	save "../temp/cumsum_expmw.dta", replace 
	restore


	qui reghdfe D.`depvar' L(-`w'/`w').D.ln_expmw D.(`controls'), ///
	absorb(`absorb') vce(cluster `cluster') nocons

				
	preserve
		coefplot, vertical base gen
		keep __at __b __se
		rename (__at __b __se) (at b_exp se_exp)
		tset at

		local winspan = 2*`w' + 1
		keep if _n<=`winspan'
		keep if !missing(at)

		gen b_exp_lb = b_exp - `t_plot'*se_exp
		gen b_exp_ub = b_exp + `t_plot'*se_exp
			
		//gen cumsum_b_exp = b_exp[1]
		//replace cumsum_b_exp = cumsum_b_exp[_n-1] + b_exp[_n] if _n > 1
		merge 1:1 at using "../temp/plot_coeffs_base.dta", nogen assert(1 2 3)
		merge 1:1 at using "../temp/cumsum_base.dta", nogen assert(1 2 3)
		merge 1:1 at using "../temp/cumsum_expmw.dta", nogen assert(1 2 3)

		sort at
		foreach var in cumsum_base_b cumsum_base_lb cumsum_base_ub cumsum_exp_b cumsum_exp_lb cumsum_exp_ub {
			replace `var' = 0 if at == `w'
		}
		// To prevent lines from overlapping perfectly
		gen at_full = at - `offset'
		gen at_base = at + `offset'

		// Figure
		make_plot_xlabels, w(`w')
		local xlab "`r(xlab)'"

		twoway (scatter b_full at_base, mcol(gs10)) (rcap b_full_lb b_full_ub at_base, lcol(gs10) lw(thin)) ///
			   (scatter b_exp at_full, mcol(navy)) (rcap b_exp_lb b_exp_ub at_full, col(navy) lw(thin)) ///
			   (line cumsum_base_b at_base, col(gs10)) (line cumsum_base_lb at_base, col(gs10) lw(thin) lp(dash)) (line cumsum_base_ub at_base, col(gs10) lw(thin) lp(dash)) ///
   			   (line cumsum_exp_b at_full, col(navy)) (line cumsum_exp_lb at_full, col(navy) lw(thin) lp(dash)) (line cumsum_exp_ub at_full, col(navy) lw(thin) lp(dash)), ///
			   yline(0, lcol(black)) ///
			   xlabel(`xlab', labsize(small)) xtitle("") ///
			   ylabel(-0.06(0.02).16, grid labsize(small)) ytitle("Coefficient") ///
			   legend(order(1 "Baseline dynamic model" 3 "Experienced MW dynamic model" 5 "Cumulative baseline" 8 "Cumulative Experienced MW") size(vsmall)) ///
			   graphregion(color(white)) bgcolor(white)
		graph export "../output/fd_model_comparison_expmw.png", replace
		graph export "../output/fd_model_comparison_expmw.eps", replace

	restore 
end

program plot_static_heterogeneity
	syntax, depvar(str) absorb(str) cluster(str) het_var(str) outstub(str) [qtles(int 4)]

	define_controls estcount avgwwage
	local emp_ctrls "`r(emp_ctrls)'"
	local estcount_ctrls "`r(estcount_ctrls)'"
	local avgwwage_ctrls "`r(avgwwage_ctrls)'"

	local controls `"`emp_ctrls' `estcount_ctrls' `avgwwage_ctrls'"'

	eststo clear
	reghdfe D.`depvar' c.d_ln_mw#i.`het_var' D.(`controls'), ///
		absorb(`absorb') ///
		vce(cluster `cluster') nocons

	coefplot, keep(*#c.d_ln_mw) base graphregion(color(white)) bgcolor(white) level(90) ///
		ylabel(1 "First quartile" 2 "Second quartile" 3 "Third quartile" 4 "Fourth quartile") ///
		ytitle(" ") xtitle("Estimated rent elasticity to the MW")	///
		xline(0, lcol(black)) mcolor(navy) ciopts(recast(rcap) lc(navy) lw(vthin))
	graph export `outstub'/fd_static_heter_`het_var'.png, replace 
	graph export `outstub'/fd_static_heter_`het_var'.eps, replace 
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