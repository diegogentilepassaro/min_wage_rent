clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../../fd_robustness/output"
	
	use "`instub'/estimates_dynamic.dta", replace
	local models "ln_mw_dynamic ln_mw_dynamic_emp ln_mw_dynamic_emp_avgwage ln_mw_dynamic_emp_avgwage_estcount" 
	gen_shift_and_bounds, modlist("`models'")

	local treatlist `" "exp_" "" "'
	foreach treat in `treatlist' {
		if "`treat'"=="exp_" {
			local stat ""
			local legend_dyn  "Coefficents of experienced ln MW"
			local legend_stat "Coefficents of ln MW" 

		} 
		else {
			local stat "exp_"
			local legend_dyn  "Coefficents of ln MW"
			local legend_stat "Coefficents of experienced ln MW" 
		}
		plot_dynamics_comp, model("`treat'") ///
		dyn_var("`treat'ln_mw") legend_dyn_var("`legend_dyn'") symbol_dyn_var(cirlce) ///
	    stat_var("`stat'ln_mw") legend_stat_var("`legend_stat'") symbol_stat_var(square) ///
		name("comp_controls_`treat'ln_mw_dynamic")
	}
end

program gen_shift_and_bounds
	syntax, modlist(str)

	gen b_lb = b - 1.96*se
	gen b_ub = b + 1.96*se

	gen at_model = at 
	local treatlist `" "exp_" "" "'
	foreach treat in `treatlist' {
		local shift = - 0.2
		foreach m in `modlist' {
			replace at_model = at_model + `shift' if model=="`treat'`m'"
			local shift = `shift' + 0.2		
		}
	}
end

program plot_dynamics_comp
    syntax, dyn_var(str) stat_var(str) ///
	    legend_dyn_var(str) symbol_dyn_var(str) ///
	    legend_stat_var(str) symbol_stat_var(str) ///
		name(str) [model(str)]
		
	preserve
	   
		twoway (scatter b at_model if model=="`model'ln_mw_dynamic" & var == "`dyn_var'", ///
		        mcol(ebblue) msymbol(`symbol_dyn_var')) ///
			(rcap b_lb b_ub at_model if model=="`model'ln_mw_dynamic" & var == "`dyn_var'", ///
			    lcol(ebblue) lw(thin)) ///
		    (scatter b at_model if model=="`model'ln_mw_dynamic" & var == "`stat_var'", ///
			    mcol(ebblue) msymbol(`symbol_stat_var')) ///
		    (rcap b_lb b_ub at_model if model=="`model'ln_mw_dynamic" & var == "`stat_var'", ///
			    col(ebblue) lw(thin)) ///
		    (scatter b at_model if model=="`model'ln_mw_dynamic_emp" & var == "`dyn_var'", ///
		        mcol(orange) msymbol(`symbol_dyn_var')) ///
			(rcap b_lb b_ub at_model if model=="`model'ln_mw_dynamic_emp" & var == "`dyn_var'", ///
			    lcol(orange) lw(thin)) ///
		    (scatter b at_model if model=="`model'ln_mw_dynamic_emp" & var == "`stat_var'", ///
			    mcol(orange) msymbol(`symbol_stat_var')) ///
		    (rcap b_lb b_ub at_model if model=="`model'ln_mw_dynamic_emp" & var == "`stat_var'", ///
			    col(orange) lw(thin)) ///
		    (scatter b at_model if model=="`model'ln_mw_dynamic_emp_avgwage" & var == "`dyn_var'", ///
		        mcol(emerald) msymbol(`symbol_dyn_var')) ///
			(rcap b_lb b_ub at_model if model=="`model'ln_mw_dynamic_emp_avgwage" & var == "`dyn_var'", ///
			    lcol(emerald) lw(thin)) ///
		    (scatter b at_model if model=="`model'ln_mw_dynamic_emp_avgwage" & var == "`stat_var'", ///
			    mcol(emerald) msymbol(`symbol_stat_var')) ///
		    (rcap b_lb b_ub at_model if model=="`model'ln_mw_dynamic_emp_avgwage" & var == "`stat_var'", ///
			    col(emerald) lw(thin)) ///
		    (scatter b at_model if model=="`model'ln_mw_dynamic_emp_avgwage_estcount" & var == "`dyn_var'", ///
		        mcol(gs10) msymbol(`symbol_dyn_var')) ///
			(rcap b_lb b_ub at_model if model=="`model'ln_mw_dynamic_emp_avgwage_estcount" & var == "`dyn_var'", ///
			    lcol(gs10) lw(thin)) ///
		    (scatter b at_model if model=="`model'ln_mw_dynamic_emp_avgwage_estcount" & var == "`stat_var'", ///
			    mcol(gs10) msymbol(`symbol_stat_var')) ///
		    (rcap b_lb b_ub at_model if model=="`model'ln_mw_dynamic_emp_avgwage_estcount" & var == "`stat_var'", ///
			    col(gs10) lw(thin)), ///
			yline(0, lcol(black)) ///
			xlabel(-6(1)6, labsize(small)) xtitle("") ///
			ylabel(-0.06(0.02).16, grid labsize(small)) ytitle("Coefficient") ///
            legend(order(1 "No Control" 5 "Employment" 9 "Employment + Wages" 13 "Employment + Wages + Establ. Count")) ///
			graphregion(color(white)) bgcolor(white)
		graph export "../output/`name'.png", replace
		graph export "../output/`name'.eps", replace
	restore
end


main
