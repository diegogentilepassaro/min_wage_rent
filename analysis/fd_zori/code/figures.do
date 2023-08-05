clear all
set more off
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000
set scheme s2color, permanently

program main
    local instub "../output"
    
    use "`instub'/estimates_zori.dta", replace
    make_bounds
    
    local y_label    "-0.1(0.02).14"
    sum at
    local w = r(max)

    offset_x_axis

    plot_dynamics_both, model(time_FE) dyn_var(mw_wkp_F)             ///
        legend_dyn_var(Workplace MW (4th Lead)) y_label(`y_label')   ///
        color_dyn_var(navy) symbol_dyn_var(cirlce)                   ///
        stat_var(mw_res_F) legend_stat_var(Residence MW (4th Lead))  ///
        color_stat_var(maroon) symbol_stat_var(square)               ///
        x_label(-`w'(1)`w') name(time_FE)
    
    plot_dynamics_both, model(cbsa_time_FE) dyn_var(mw_wkp_F)        ///
        legend_dyn_var(Workplace MW (4th Lead)) y_label(`y_label')   ///
        color_dyn_var(navy) symbol_dyn_var(cirlce)                   ///
        stat_var(mw_res_F) legend_stat_var(Residence MW (4th Lead))  ///
        color_stat_var(maroon) symbol_stat_var(square)               ///
        x_label(-`w'(1)`w') name(cbsa_time_FE)
    
end


main
