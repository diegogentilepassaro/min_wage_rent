clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../../fd_baseline/output"
	
	use "`instub'/estimates_baseline_dynamic.dta", replace
	gen at_right = at + 0.1
	gen at_left = at - 0.1

	gen b_lb = b - 1.96*se
	gen b_ub = b + 1.96*se
	
    twoway (scatter b at if var == "exp_ln_mw", mcol(navy)) ///
	    (rcap b_lb b_ub at if var == "exp_ln_mw", lcol(navy) lw(thin)) ///
	    (scatter b at_right if var == "ln_mw", mcol(maroon)) ///
		(rcap b_lb b_ub at_right if var == "ln_mw", col(maroon) lw(thin)) ///
        (line b at_left if var == "cumsum_from0", col(navy)) ///
		 	(line b_lb at_left if var == "cumsum_from0", col(navy) lw(thin) lp(dash)) ///
			(line b_ub at_left if var == "cumsum_from0", col(navy) lw(thin) lp(dash)), ///
	    yline(0, lcol(black)) ///
	    xlabel(-6(1)6, labsize(small)) xtitle("") ///
	    ylabel(-0.06(0.02).16, grid labsize(small)) ytitle("Coefficient") ///
	    legend(order(1 "Coefficents of experienced ln MW" ///
		    3 "Coefficents of ln MW" ///
		 	5 "Cumulative sum") size(vsmall)) ///
	    graphregion(color(white)) bgcolor(white)
	graph export "../output/fd_baseline.png", replace
	graph export "../output/fd_baseline.eps", replace
end

main
