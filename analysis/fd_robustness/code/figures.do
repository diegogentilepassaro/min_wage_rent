clear all
set more off
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
    local instub "../output"
    
    use "`instub'/estimates_dynamic.dta", replace
    make_bounds
    offset_x_axis
    
    local y_label    "-0.20(0.04)0.28"
    local mw_wkp_var "mw_wkp_tot_17"
    sum at
    local w = r(max)
    
	local models "SF CC Studio 1BR 2BR 3BR Mfr5Plus"
	foreach model of local models {
        plot_dynamics_both, model(`model'_rents_dyn) dyn_var(`mw_wkp_var') ///
            legend_dyn_var(Workplace MW) y_label(`y_label') ///
            color_dyn_var(navy) symbol_dyn_var(cirlce) ///
            stat_var(mw_res) legend_stat_var(Residence MW) ///
            color_stat_var(maroon) symbol_stat_var(square) ///
            x_label(-6(1)6) name(fd_`model'_both_mw_wkp_only_dyn)
	}
	
	plot_dynamics_both, model(monthly_listings) dyn_var(`mw_wkp_var') ///
		legend_dyn_var(Workplace MW) y_label(-1(0.2)1) ///
		color_dyn_var(navy) symbol_dyn_var(cirlce) ///
		stat_var(mw_res) legend_stat_var(Residence MW) ///
		color_stat_var(maroon) symbol_stat_var(square) ///
		x_label(-6(1)6) name(fd_monthly_listings_both_mw_wkp_only_dyn)
		
	plot_dynamics_both, model(monthly_listings_fullbal) dyn_var(`mw_wkp_var') ///
		legend_dyn_var(Workplace MW) y_label(-1(0.2)1) ///
		color_dyn_var(navy) symbol_dyn_var(cirlce) ///
		stat_var(mw_res) legend_stat_var(Residence MW) ///
		color_stat_var(maroon) symbol_stat_var(square) ///
		x_label(-6(1)6) name(fd_monthly_listings_both_mw_wkp_only_dyn_fullbal)
		
	plot_dynamics_both, model(monthly_listings_unbal) dyn_var(`mw_wkp_var') ///
		legend_dyn_var(Workplace MW) y_label(-1(0.2)1) ///
		color_dyn_var(navy) symbol_dyn_var(cirlce) ///
		stat_var(mw_res) legend_stat_var(Residence MW) ///
		color_stat_var(maroon) symbol_stat_var(square) ///
		x_label(-6(1)6) name(fd_monthly_listings_both_mw_wkp_only_dyn_unbal)
end

main
