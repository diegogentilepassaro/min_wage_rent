program plot_dynamics_both
    syntax, model(str) dyn_var(str) stat_var(str) y_label(str) ///
        legend_dyn_var(str) color_dyn_var(str) symbol_dyn_var(str) ///
        legend_stat_var(str) color_stat_var(str) symbol_stat_var(str) ///
        x_label(str) name(str) [width(int 2221) height(int 1615)]
    
    if inlist("`stat_var'", "mw_res", "mw_res_avg") {
        local at_stat "at_l"
        local at_dyn  "at_r"
        local leg_num_fir  "5"
        local leg_name_fir `"`legend_stat_var'"'
        local leg_num_sec  "1"
        local leg_name_sec `"`legend_dyn_var'"'
    }
    else {
        local at_stat "at_r"
        local at_dyn  "at_l"
        local leg_num_fir  "1"
        local leg_name_fir `"`legend_dyn_var'"'
        local leg_num_sec  "5"
        local leg_name_sec `"`legend_stat_var'"'
    }

    local at_dyn0  "at"
    if "`name'" == "fd_both_dynamic" {
        local at_dyn0  "`at_dyn'"
    }

    preserve
        keep if model == "`model'"
        twoway  (scatter b      `at_dyn'  if var == "`dyn_var'" & at == 0,      ///
                     mcol(`color_dyn_var') msymbol(`symbol_dyn_var'))           ///
                (scatter b      `at_dyn0' if var == "`dyn_var'" & at != 0,      ///
                     mcol(`color_dyn_var') msymbol(`symbol_dyn_var'))           ///
                (rcap b_lb b_ub `at_dyn'  if var == "`dyn_var'" & at == 0,      ///
                    lcol(`color_dyn_var') lw(thin))                             ///
                (rcap b_lb b_ub `at_dyn0' if var == "`dyn_var'" & at != 0,      ///
                    lcol(`color_dyn_var') lw(thin))                             ///
                (scatter b      `at_stat' if var == "`stat_var'",               ///
                    mcol(`color_stat_var') msymbol(`symbol_stat_var'))          ///
                (rcap b_lb b_ub `at_stat' if var == "`stat_var'",               ///
                    col(`color_stat_var') lw(thin)),                            ///
            yline(0, lcol(grey) lpattern(dot))                                  ///
            xlabel(`x_label', labsize(small)) xtitle("")                        ///
            ylabel(`y_label', grid labsize(small)) ytitle("Coefficient")        ///
            legend(order(`leg_num_fir' `"`leg_name_fir'"'                       ///
                         `leg_num_sec' `"`leg_name_sec'"'))                     ///
            graphregion(color(white)) bgcolor(white)
        
        graph export "../output/`name'_png.png", replace width(`width') height(`height')
        graph export "../output/`name'.eps", replace
    restore
end
