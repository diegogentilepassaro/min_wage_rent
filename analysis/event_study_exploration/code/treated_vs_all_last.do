clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../temp"
	local outstub "../output"

	local controls "i.cumsum_unused_events"
	local cluster_se "statefips"

	local ZFE 		"zipcode 	year_month"
	local ZFE_trend "zipcode 	year_month c.trend#i.countyfips c.trend_sq#i.countyfips"
	local CFE 		"countyfips year_month"
	local CFE_trend "countyfips year_month c.trend#i.countyfips c.trend_sq#i.countyfips"

	local yaxis "ylabel(-0.02(0.02)0.06) yscale(range(-0.02(0.02)0.06))"

	foreach data in rent listing {
		use "`instub'/baseline_`data'_panel_6.dta", clear

		if "`data'" == "rent" {
			local stand_yaxis "yaxis(`yaxis')"
		}
		else {
			local stand_yaxis " "
		}

		foreach depvar in psqft_sfcc {
			create_event_plot_with_untreated, depvar(med`data'price`depvar') 	///
				event_var(last_sal_mw_event_rel_months6) 						///
				controls(`controls') window(6)									///
				absorb(`ZFE') cluster(`cluster_se')
			graph export "`outstub'/last_`data'`depvar'_w6_zfe_with-untreated.png", replace

			create_event_plot_with_untreated, depvar(med`data'price`depvar') 	///
				event_var(last_sal_mw_event_rel_months6) 						///
				controls(`controls') window(6)									///
				absorb(`ZFE_trend') cluster(`cluster_se')
			graph export "`outstub'/last_`data'`depvar'_w6_zfe-county-trend_with-untreated.png", replace

			create_event_plot_with_untreated, depvar(med`data'price`depvar') 	///
				event_var(last_sal_mw_event_rel_months6) 						///
				controls(`controls') window(6)									///
				absorb(`CFE') cluster(`cluster_se')
			graph export "`outstub'/last_`data'`depvar'_w6_cfe_with-untreated.png", replace

			create_event_plot_with_untreated, depvar(med`data'price`depvar') 	///
				event_var(last_sal_mw_event_rel_months6) 						///
				controls(`controls') window(6)									///
				absorb(`CFE_trend') cluster(`cluster_se')
			graph export "`outstub'/last_`data'`depvar'_w6_cfe-county-trend_with-untreated.png", replace
		}
	}
end

main
