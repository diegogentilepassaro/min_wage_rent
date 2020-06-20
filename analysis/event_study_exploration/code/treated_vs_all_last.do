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

	foreach data in rent listing {
		use "`instub'/baseline_`data'_panel_6.dta", clear

		foreach depvar in psqft_sfcc { 
			foreach FE in ZFE CFE {
				create_event_plot_with_untreated, depvar(med`data'price`depvar') 	///
					event_var(last_sal_mw_event_rel_months6) 						///
					controls(`controls') window(6)									///
					absorb(`FE') cluster(`cluster_se')
				graph export "`outstub'/last_`data'`depvar'_w6_`FE'_with-untreated.png", replace

				create_event_plot_with_untreated, depvar(med`data'price`depvar') 	///
					event_var(last_sal_mw_event_rel_months6) 						///
					controls(`controls') window(6)									///
					absorb(`FE'_trend) cluster(`cluster_se')
				graph export "`outstub'/last_`data'`depvar'_w6_`FE'_with-untreated_county-trend.png", replace
			}
		}
	}
end

main
