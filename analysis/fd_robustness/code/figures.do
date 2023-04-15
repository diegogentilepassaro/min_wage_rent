clear all
set more off
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
    local instub "../output"
    
    use "`instub'/estimates_dynamic.dta", replace
    make_bounds
    offset_x_axis
    
    local y_label    "-0.25(0.05)0.3"
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
    
	plot_dynamics_both, model(time_fe_baseline_rents) dyn_var(`mw_wkp_var') ///
        legend_dyn_var(Workplace MW) y_label(`y_label') ///
        color_dyn_var(navy) symbol_dyn_var(cirlce) ///
        stat_var(mw_res) legend_stat_var(Residence MW) ///
        color_stat_var(maroon) symbol_stat_var(square) ///
        x_label(-6(1)6) name(fd_time_fe_baseline_wkp_dyn)
	
    foreach geo in statefips cbsa county {
        plot_dynamics_both, model(time_fe_`geo'_rents) dyn_var(`mw_wkp_var') ///
            legend_dyn_var(Workplace MW) y_label(`y_label') ///
            color_dyn_var(navy) symbol_dyn_var(cirlce) ///
            stat_var(mw_res) legend_stat_var(Residence MW) ///
            color_stat_var(maroon) symbol_stat_var(square) ///
            x_label(-6(1)6) name(fd_time_fe_`geo'_wkp_dyn)
    }

	plot_dynamics_both, model(monthly_listings) dyn_var(`mw_wkp_var') ///
		legend_dyn_var(Workplace MW) y_label(-1(0.2)1) ///
		color_dyn_var(navy) symbol_dyn_var(cirlce) ///
		stat_var(mw_res) legend_stat_var(Residence MW) ///
		color_stat_var(maroon) symbol_stat_var(square) ///
		x_label(-6(1)6) name(fd_monthly_listings_both_mw_wkp_only_dyn)
		
	plot_dynamics_both, model(monthly_listings_by_cbsa) dyn_var(`mw_wkp_var') ///
		legend_dyn_var(Workplace MW) y_label(-1(0.2)1) ///
		color_dyn_var(navy) symbol_dyn_var(cirlce) ///
		stat_var(mw_res) legend_stat_var(Residence MW) ///
		color_stat_var(maroon) symbol_stat_var(square) ///
		x_label(-6(1)6) name(fd_monthly_listings_both_mw_wkp_only_dyn_by_cbsa)
		
	plot_dynamics_both, model(prices_psqft) dyn_var(`mw_wkp_var') ///
		legend_dyn_var(Workplace MW) y_label(-0.1(0.05)0.1) ///
		color_dyn_var(navy) symbol_dyn_var(cirlce) ///
		stat_var(mw_res) legend_stat_var(Residence MW) ///
		color_stat_var(maroon) symbol_stat_var(square) ///
		x_label(-6(1)6) name(fd_prices_psqft_both_mw_wkp_only_dyn)
		
	plot_dynamics_both, model(prices_psqft_by_cbsa) dyn_var(`mw_wkp_var') ///
		legend_dyn_var(Workplace MW) y_label(-0.1(0.05)0.1) ///
		color_dyn_var(navy) symbol_dyn_var(cirlce) ///
		stat_var(mw_res) legend_stat_var(Residence MW) ///
		color_stat_var(maroon) symbol_stat_var(square) ///
		x_label(-6(1)6) name(fd_prices_psqft_both_mw_wkp_only_dyn_by_cbsa)
end

main
