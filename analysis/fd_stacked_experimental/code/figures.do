clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
    use "../output/estimates_stacked_dyn.dta", clear
    make_bounds
    
    local y_label       "-0.16(0.04).2"
    local exp_ln_mw_var "exp_ln_mw_17"
    sum at
    local w = r(max)

    offset_x_axis

    plot_dynamics_both, model(stacked_dyn_w6) dyn_var(d_exp_ln_mw) ///
        legend_dyn_var(Workplace MW) y_label(`y_label') ///
        color_dyn_var(navy) symbol_dyn_var(cirlce) ///
        stat_var(d_ln_mw) legend_stat_var(Residence MW) ///
        color_stat_var(maroon) symbol_stat_var(square) ///
        x_label(-6(1)6) name(fd_stacked_w6)
        
    plot_dynamics_both, model(stacked_dyn_w3) dyn_var(d_exp_ln_mw) ///
        legend_dyn_var(Workplace MW) y_label(`y_label') ///
        color_dyn_var(navy) symbol_dyn_var(cirlce) ///
        stat_var(d_ln_mw) legend_stat_var(Residence MW) ///
        color_stat_var(maroon) symbol_stat_var(square) ///
        x_label(-3(1)3)  name(fd_stacked_w3)
		
    plot_dynamics_both, model(stacked_dyn_w9) dyn_var(d_exp_ln_mw) ///
        legend_dyn_var(Workplace MW) y_label(`y_label') ///
        color_dyn_var(navy) symbol_dyn_var(cirlce) ///
        stat_var(d_ln_mw) legend_stat_var(Residence MW) ///
        color_stat_var(maroon) symbol_stat_var(square) ///
        x_label(-9(1)9) name(fd_stacked_w9)
end

program make_bounds
    gen b_lb = b - 1.96*se
    gen b_ub = b + 1.96*se
end

program offset_x_axis
    syntax, [k(real 0.15)]
    cap drop at_r at_l
    gen at_r = at + `k'
    gen at_l = at - `k'
end

program plot_dynamics_both
    syntax, model(str) dyn_var(str) stat_var(str) y_label(str) ///
        legend_dyn_var(str) color_dyn_var(str) symbol_dyn_var(str) ///
        legend_stat_var(str) color_stat_var(str) symbol_stat_var(str) ///
        x_label(str) name(str)
        
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
                    col(`color_stat_var') lw(thin)),                            ///
            yline(0, lcol(black))                                               ///
            xlabel(`x_label', labsize(small)) xtitle("")                           ///
            ylabel(`y_label', grid labsize(small)) ytitle("Coefficient")        ///
            legend(order(1 `"`legend_dyn_var'"' 5 `"`legend_stat_var'"' ))      ///
            graphregion(color(white)) bgcolor(white)
        
        graph export "../output/`name'.png", replace
        graph export "../output/`name'.eps", replace
    restore
end


main
