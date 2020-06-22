clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../temp"
	local outstub "../output"

	local controls "i.cumsum_unused_events"

	local ZFE "zipcode year_month"
	local ZFE_trend "zipcode year_month c.trend#i.countyfips c.trend_sq#i.countyfips"
	local CFE "countyfips year_month"
	local CFE_trend "countyfips year_month c.trend#i.countyfips c.trend_sq#i.countyfips"
	local cluster_se "statefips"

	foreach data in rent listing {
		use "`instub'/baseline_`data'_panel_6.dta" if treated, clear

		foreach depvar in psqft_sfcc {
			
			create_event_plot, depvar(med`data'price`depvar') 				///
				event_var(last_sal_mw_event_rel_months6) 					///
				controls(`controls') window(6)								///
				absorb(`ZFE') cluster(`cluster_se')
			graph export "`outstub'/last_`data'`depvar'_zfe_w6.png", replace

			create_event_plot, depvar(med`data'price`depvar') 				///
				event_var(last_sal_mw_event_rel_months6) 					///
				controls(`controls') window(6)								///
				absorb(`ZFE_trend') cluster(`cluster_se')
			graph export "`outstub'/last_`data'`depvar'_zfe_w6_county-trend.png", replace

			create_event_plot, depvar(med`data'price`depvar') 				///
				event_var(last_sal_mw_event_rel_months6) 					///
				controls(`controls') window(6)								///
				absorb(`CFE') cluster(`cluster_se')
			graph export "`outstub'/last_`data'`depvar'_cfe_w6.png", replace

			create_event_plot, depvar(med`data'price`depvar') 				///
				event_var(last_sal_mw_event_rel_months6) 					///
				controls(`controls') window(6)								///
				absorb(`CFE_trend') cluster(`cluster_se')
			graph export "`outstub'/last_`data'`depvar'_cfe_w6_county-trend.png", replace
		}
	}
end

main
