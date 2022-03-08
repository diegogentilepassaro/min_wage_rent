clear all
set more off
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
    local instub "../../fd_baseline/output"
    
    use "`instub'/estimates_dynamic.dta", replace
    make_bounds
    
    local y_label    "-0.08(0.02).14"
    local mw_wkp_var "mw_wkp_tot_17"
    sum at
    local w = r(max)
    
    plot_dynamics, model(mw_res_only_dynamic) var(mw_res) ///
        legend_var(Residence MW) y_label(`y_label') ///
        color(maroon) symbol(square) ///
        name(fd_mw_res_only_dynamic)
        
    plot_dynamics, model(mw_wkp_only_dynamic) var(`mw_wkp_var') ///
        legend_var(Workplace MW) y_label(`y_label') ///
        color(navy) symbol(circle) ///
        name(fd_mw_wkp_only_dynamic)
    
    offset_x_axis

    plot_dynamics_both, model(both_mw_wkp_dynamic) dyn_var(`mw_wkp_var') ///
        legend_dyn_var(Workplace MW) y_label(`y_label') ///
        color_dyn_var(navy) symbol_dyn_var(cirlce) ///
        stat_var(mw_res) legend_stat_var(Residence MW) ///
        color_stat_var(maroon) symbol_stat_var(square) ///
        x_label(-6(1)6) name(fd_both_mw_wkp_only_dynamic)
        
    plot_dynamics_both, model(both_mw_res_dynamic) dyn_var(mw_res) ///
        legend_dyn_var(Residence MW) y_label(`y_label') ///
        color_dyn_var(maroon) symbol_dyn_var(square) ///
        stat_var(`mw_wkp_var') legend_stat_var(Workplace MW) ///
        color_stat_var(navy) symbol_stat_var(circle) ///
        x_label(-6(1)6) name(fd_both_mw_res_only_dynamic)
	
    offset_x_axis, k(0.3)

    plot_dynamics_both, model(both_dynamic) dyn_var(mw_res) ///
        legend_dyn_var(Residence MW) y_label(`y_label') ///
        color_dyn_var(maroon) symbol_dyn_var(square) ///
        stat_var(`mw_wkp_var') legend_stat_var(Workplace MW) ///
        color_stat_var(navy) symbol_stat_var(circle) ///
        x_label(-6(1)6) name(fd_both_dynamic)
end

main
