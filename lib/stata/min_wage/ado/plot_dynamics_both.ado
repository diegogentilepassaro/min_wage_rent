program plot_dynamics_both
    syntax, model(str) dyn_var(str) stat_var(str) y_label(str) ///
        legend_dyn_var(str) color_dyn_var(str) symbol_dyn_var(str) ///
        legend_stat_var(str) color_stat_var(str) symbol_stat_var(str) ///
        x_label(str) name(str) [width(int 2221) height(int 1615)]
        
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
            yline(0, lcol(grey) lpattern(dot))                                               ///
            xlabel(`x_label', labsize(small)) xtitle("")               ///
            ylabel(`y_label', grid labsize(small)) ytitle("Coefficient")        ///
            legend(order(1 `"`legend_dyn_var'"' 5 `"`legend_stat_var'"' ))      ///
            graphregion(color(white)) bgcolor(white)
        
        graph export "../output/`name'.png", replace width(`width') height(`height')
        graph export "../output/`name'.eps", replace
    restore
end
