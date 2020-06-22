clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../temp"
	local outstub "../output"

	local ZFE 		"zipcode year_month"
	local ZFE_trend "zipcode year_month c.trend#i.countyfips c.trend_sq#i.countyfips"
	local cluster_se "statefips"
	local yaxis "ylabel(-0.01(0.01)0.05) yscale(range(-0.01(0.01)0.05))"

	foreach w in 6 {
		foreach depvar in psqft_sfcc {
			foreach data in rent {

				use "`instub'/baseline_`data'_panel_`w'.dta", clear
				
				rename treated_mw_event025_6 treated

				create_event_plot_with_untreated, depvar(med`data'price`depvar') 	///
					event_var(last_mw_event025_rel_months`w') 						///
					controls("i.c_unused_mw_event025_`w'") window(`w')				///
					absorb(`ZFE') cluster(`cluster_se') yaxis(`yaxis')
				graph export "../output/last_`data'`depvar'_event025_w`w'.png", replace

				create_event_plot_with_untreated, depvar(med`data'price`depvar') 	///
					event_var(last_mw_event025_rel_months`w') 						///
					controls("i.c_unused_mw_event025_`w'") window(`w')				///
					absorb(`ZFE_trend') cluster(`cluster_se') yaxis(`yaxis')
				graph export "../output/last_`data'`depvar'_event025_w`w'_county-trend.png", replace
				
				drop treated
				rename treated_mw_event075_6 treated

				create_event_plot_with_untreated, depvar(med`data'price`depvar') 	///
					event_var(last_mw_event075_rel_months`w') 						///
					controls("i.c_unused_mw_event075_`w'") window(`w')				///
					absorb(`ZFE') cluster(`cluster_se') yaxis(`yaxis')
				graph export "`outstub'/last_`data'`depvar'_event075_w`w'.png", replace

				create_event_plot_with_untreated, depvar(med`data'price`depvar') 	///
					event_var(last_mw_event075_rel_months`w') 						///
					controls("i.c_unused_mw_event075_`w'") window(`w')				///
					absorb(`ZFE_trend') cluster(`cluster_se') yaxis(`yaxis')
				graph export "`outstub'/last_`data'`depvar'_event075_w`w'_county-trend.png", replace
			}

		use "`instub'/baseline_rent_panel_`w'.dta" if treated_mw_event025_6, clear

		create_event_plot, depvar(medrentprice`depvar') 							///
			event_var(last_mw_event025_rel_months`w') 								///
			controls("i.c_unused_mw_event025_`w'") window(`w')						///
			absorb(`ZFE') cluster(`cluster_se') yaxis(`yaxis')
		graph export "../output/last_rent`depvar'_event025_w`w'_treated-only.png", replace
		
		use "`instub'/baseline_rent_panel_`w'.dta" if treated_mw_event075_6, clear

		create_event_plot, depvar(medrentprice`depvar') 							///
			event_var(last_mw_event075_rel_months`w') 								///
			controls("i.c_unused_mw_event075_`w'") window(`w')						///
			absorb(`ZFE') cluster(`cluster_se') yaxis(`yaxis')
		graph export "`outstub'/last_rent`depvar'_event075_w`w'_treated-only.png", replace
		}
	}
end

main
