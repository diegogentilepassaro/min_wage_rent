clear all
set more off
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	foreach w in 3 6 9 {
		use "../output/estimates_stacked_dyn_w`w'.dta", clear
		make_bounds
		
		local y_label       "-0.16(0.04).2"
		local mw_wkp_var    "d_mw_wkp_tot_17"
		sum at
		local w = r(max)

		offset_x_axis

		plot_dynamics_both, model(mw_wkp_only_dynamic_w`w') dyn_var(`mw_wkp_var') ///
			legend_dyn_var(Workplace MW) y_label(`y_label') ///
			color_dyn_var(navy) symbol_dyn_var(cirlce) ///
			stat_var(d_mw_res) legend_stat_var(Residence MW) ///
			color_stat_var(maroon) symbol_stat_var(square) ///
			x_label(-`w'(1)`w') name(fd_mw_wkp_only_dynamic_w`w')	
	}
end

main
