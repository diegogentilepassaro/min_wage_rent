program plot_dynamics
    syntax, model(str) var(str) y_label(str) ///
        legend_var(str) color(str) symbol(str) ///
        name(str)
        
    preserve
        keep if model == "`model'"
        twoway (scatter b       at if var == "`var'", mcol(`color') msymbol(`symbol')) ///
                (rcap b_lb b_ub at if var == "`var'", lcol(`color') lw(thin)),         ///
            yline(0, lcol(black))                                                      ///
            xlabel(-6(1)6, labsize(small)) xtitle("")                                  ///
            ylabel(`y_label', grid labsize(small)) ytitle("Coefficient")               ///
            legend(order(1 `"`legend_var'"'))                                          ///
            graphregion(color(white)) bgcolor(white)
        
        graph export "../output/`name'.png", replace
        graph export "../output/`name'.eps", replace
    restore
end