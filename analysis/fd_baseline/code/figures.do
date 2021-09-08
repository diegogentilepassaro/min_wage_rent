clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../../fd_baseline/output"
	
	use "`instub'/estimates_dynamic.dta", replace
	gen_shift_and_bounds
	
    plot_dynamics, model(ln_mw_only_dynamic) var(ln_mw) ///
	    legend_var(Coefficents of ln MW) ///
		color(maroon) symbol(square) ///
		name(fd_ln_mw_only_dynamic)
		
    plot_dynamics, model(exp_ln_mw_only_dynamic) var(exp_ln_mw) ///
	    legend_var(Coefficents of experienced ln MW) ///
		color(navy) symbol(circle) ///
		name(fd_exp_ln_mw_only_dynamic)
		
    plot_dynamics_both, model(baseline_exp_ln_mw_dynamic) dyn_var(exp_ln_mw) ///
	    legend_dyn_var(Coefficents of experienced ln MW) ///
		color_dyn_var(navy) symbol_dyn_var(cirlce) ///
	    stat_var(ln_mw) legend_stat_var(Coefficent of ln MW) ///
		color_stat_var(maroon) symbol_stat_var(square) ///
		name(fd_baseline_exp_ln_mw_dynamic)
		
    plot_dynamics_both, model(both_ln_mw_dynamic) dyn_var(ln_mw) ///
	    legend_dyn_var(Coefficents of ln MW) ///
		color_dyn_var(maroon) symbol_dyn_var(square) ///
	    stat_var(exp_ln_mw) legend_stat_var(Coefficent of experienced ln MW) ///
		color_stat_var(navy) symbol_stat_var(circle) ///
		name(fd_both_ln_mw_dynamic)
end

program gen_shift_and_bounds
	gen at_right = at + 0.1
	gen at_left = at - 0.1

	gen b_lb = b - 1.96*se
	gen b_ub = b + 1.96*se
end

program plot_dynamics
    syntax, model(str) var(str) ///
	    legend_var(str) color(str) symbol(str) ///
		name(str)
		
	preserve
	    keep if model == "`model'"
		twoway (scatter b at if var == "`var'", mcol(`color') msymbol(`symbol')) ///
			(rcap b_lb b_ub at if var == "`var'", lcol(`color') lw(thin)) ///
			(line b at_left if var == "cumsum_from0", col(`color')) ///
				(line b_lb at_left if var == "cumsum_from0", ///
				    col(`color') lw(thin) lp(dash)) ///
				(line b_ub at_left if var == "cumsum_from0", ///
				    col(`color') lw(thin) lp(dash)), ///
			yline(0, lcol(black)) ///
			xlabel(-6(1)6, labsize(small)) xtitle("") ///
			ylabel(-0.06(0.02).16, grid labsize(small)) ytitle("Coefficient") ///
            legend(order(1 `"`legend_var'"' 3 "Cumulative sum")) ///
			graphregion(color(white)) bgcolor(white)
		graph export "../output/`name'.png", replace
		graph export "../output/`name'.eps", replace
	restore
end

program plot_dynamics_both
    syntax, model(str) dyn_var(str) stat_var(str) ///
	    legend_dyn_var(str) color_dyn_var(str) symbol_dyn_var(str) ///
	    legend_stat_var(str) color_stat_var(str) symbol_stat_var(str) ///
		name(str)
		
	preserve
	    keep if model == "`model'"
		twoway (scatter b at if var == "`dyn_var'", ///
		        mcol(`color_dyn_var') msymbol(`symbol_dyn_var')) ///
			(rcap b_lb b_ub at if var == "`dyn_var'", ///
			    lcol(`color_dyn_var') lw(thin)) ///
		    (scatter b at_right if var == "`stat_var'", ///
			    mcol(`color_stat_var') msymbol(`symbol_stat_var')) ///
		    (rcap b_lb b_ub at_right if var == "`stat_var'", ///
			    col(`color_stat_var') lw(thin)) ///
			(line b at_left if var == "cumsum_from0", col(`color_dyn_var')) ///
				(line b_lb at_left if var == "cumsum_from0", ///
				    col(`color_dyn_var') lw(thin) lp(dash)) ///
				(line b_ub at_left if var == "cumsum_from0", ///
				    col(`color_dyn_var') lw(thin) lp(dash)), ///
			yline(0, lcol(black)) ///
			xlabel(-6(1)6, labsize(small)) xtitle("") ///
			ylabel(-0.06(0.02).16, grid labsize(small)) ytitle("Coefficient") ///
            legend(order(1 `"`legend_dyn_var'"' 3 `"`legend_stat_var'"' ///
			    5 "Cumulative sum")) ///
			graphregion(color(white)) bgcolor(white)
		graph export "../output/`name'.png", replace
		graph export "../output/`name'.eps", replace
	restore
end


main
