clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
    local instub "../../fd_baseline/output"
    
    use "`instub'/estimates_dynamic.dta", replace
    make_bounds
    
    local exp_ln_mw_var "exp_ln_mw_17"
    sum at
    local w = r(max)
    
    plot_dynamics, model(ln_mw_only_dynamic) var(ln_mw) ///
        legend_var(Residence MW) ///
        color(maroon) symbol(square) ///
        name(fd_ln_mw_only_dynamic)
        
    plot_dynamics, model(`exp_ln_mw_var'_only_dynamic) var(`exp_ln_mw_var') ///
        legend_var(Workplace MW) ///
        color(navy) symbol(circle) ///
        name(fd_`exp_ln_mw_var'_only_dynamic)
    
    offset_x_axis

    plot_dynamics_both, model(baseline_`exp_ln_mw_var'_dynamic) dyn_var(`exp_ln_mw_var') ///
        legend_dyn_var(Workplace MW) ///
        color_dyn_var(navy) symbol_dyn_var(cirlce) ///
        stat_var(ln_mw) legend_stat_var(Residence MW) ///
        color_stat_var(maroon) symbol_stat_var(square) ///
        name(fd_baseline_`exp_ln_mw_var'_dynamic)
        
    plot_dynamics_both, model(both_ln_mw_dynamic) dyn_var(ln_mw) ///
        legend_dyn_var(Residence MW) ///
        color_dyn_var(maroon) symbol_dyn_var(square) ///
        stat_var(`exp_ln_mw_var') legend_stat_var(Workplace MW) ///
        color_stat_var(navy) symbol_stat_var(circle) ///
        name(fd_both_ln_mw_dynamic)
	
    plot_dynamics_both, model(both_dynamic) dyn_var(ln_mw) ///
        legend_dyn_var(Residence MW) ///
        color_dyn_var(maroon) symbol_dyn_var(square) ///
        stat_var(`exp_ln_mw_var') legend_stat_var(Workplace MW) ///
        color_stat_var(navy) symbol_stat_var(circle) ///
        name(fd_both_dynamic)
end

program make_bounds
    gen b_lb = b - 1.96*se
    gen b_ub = b + 1.96*se
end

program offset_x_axis
    gen at_r = at + 0.15
    gen at_l = at - 0.15
end

program plot_dynamics
    syntax, model(str) var(str) ///
        legend_var(str) color(str) symbol(str) ///
        name(str)
        
    preserve
        keep if model == "`model'"
        twoway (scatter b       at if var == "`var'", mcol(`color') msymbol(`symbol')) ///
                (rcap b_lb b_ub at if var == "`var'", lcol(`color') lw(thin)),                                   ///
            yline(0, lcol(black))                                                      ///
            xlabel(-6(1)6, labsize(small)) xtitle("")                                  ///
            ylabel(-0.06(0.02).16, grid labsize(small)) ytitle("Coefficient")          ///
            legend(order(1 `"`legend_var'"'))                       ///
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
        twoway  (scatter b      at_r if var == "`dyn_var'" & at == 0,           ///
                     mcol(`color_dyn_var') msymbol(`symbol_dyn_var'))           ///
                (scatter b      at   if var == "`dyn_var'" & at != 0,           ///
                     mcol(`color_dyn_var') msymbol(`symbol_dyn_var'))           ///
                (rcap b_lb b_ub at_r if var == "`dyn_var'" & at == 0,           ///
                    lcol(`color_dyn_var') lw(thin))                             ///
                (rcap b_lb b_ub at   if var == "`dyn_var'" & at != 0,           ///
                    lcol(`color_dyn_var') lw(thin))                             ///
                (scatter b      at_l if var == "`stat_var'",                    ///
                    mcol(`color_stat_var') msymbol(`symbol_stat_var'))          ///
                (rcap b_lb b_ub at_l if var == "`stat_var'",                    ///
                    col(`color_stat_var') lw(thin)),                    ///
            yline(0, lcol(black))                                               ///
            xlabel(-6(1)6, labsize(small)) xtitle("")                           ///
            ylabel(-0.06(0.02).16, grid labsize(small)) ytitle("Coefficient")   ///
            legend(order(1 `"`legend_dyn_var'"' 5 `"`legend_stat_var'"' ))                                            ///
            graphregion(color(white)) bgcolor(white)
        
        graph export "../output/`name'.png", replace
        graph export "../output/`name'.eps", replace
    restore
end


main
