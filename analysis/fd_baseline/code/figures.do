clear all
set more off
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
    local instub "../../fd_baseline/output"
    
    use "`instub'/estimates_dynamic.dta", replace
    make_bounds
    
    local y_label       "-0.08(0.02).14"
    local exp_ln_mw_var "exp_ln_mw_17"
    sum at
    local w = r(max)
    
    plot_dynamics, model(ln_mw_only_dynamic) var(ln_mw) ///
        legend_var(Residence MW) y_label(`y_label') ///
        color(maroon) symbol(square) ///
        name(fd_ln_mw_only_dynamic)
        
    plot_dynamics, model(`exp_ln_mw_var'_only_dynamic) var(`exp_ln_mw_var') ///
        legend_var(Workplace MW) y_label(`y_label') ///
        color(navy) symbol(circle) ///
        name(fd_`exp_ln_mw_var'_only_dynamic)
    
    offset_x_axis

    plot_dynamics_both, model(baseline_`exp_ln_mw_var'_dynamic) dyn_var(`exp_ln_mw_var') ///
        legend_dyn_var(Workplace MW) y_label(`y_label') ///
        color_dyn_var(navy) symbol_dyn_var(cirlce) ///
        stat_var(ln_mw) legend_stat_var(Residence MW) ///
        color_stat_var(maroon) symbol_stat_var(square) ///
        x_label(-6(1)6) name(fd_baseline_`exp_ln_mw_var'_dynamic)
        
    plot_dynamics_both, model(both_ln_mw_dynamic) dyn_var(ln_mw) ///
        legend_dyn_var(Residence MW) y_label(`y_label') ///
        color_dyn_var(maroon) symbol_dyn_var(square) ///
        stat_var(`exp_ln_mw_var') legend_stat_var(Workplace MW) ///
        color_stat_var(navy) symbol_stat_var(circle) ///
        x_label(-6(1)6) name(fd_both_ln_mw_dynamic)
	
    offset_x_axis, k(0.3)

    plot_dynamics_both, model(both_dynamic) dyn_var(ln_mw) ///
        legend_dyn_var(Residence MW) y_label(`y_label') ///
        color_dyn_var(maroon) symbol_dyn_var(square) ///
        stat_var(`exp_ln_mw_var') legend_stat_var(Workplace MW) ///
        color_stat_var(navy) symbol_stat_var(circle) ///
        x_label(-6(1)6) name(fd_both_dynamic)
end

main
