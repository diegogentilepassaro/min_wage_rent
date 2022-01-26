clear all
set more off
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
end

main
