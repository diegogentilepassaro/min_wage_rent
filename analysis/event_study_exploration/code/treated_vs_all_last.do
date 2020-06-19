clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../temp"
	local outstub "../output"

	local controls "i.cumsum_unused_events"
	local CFE "countyfips year_month c.trend#i.countyfips c.trend_sq#i.countyfips"
	local cluster_se "statefips"

	foreach data in rent listing {
		use "`instub'/baseline_`data'_panel_6.dta", clear
		foreach depvar in psqft_sfcc { 
			
			create_event_plot, depvar(med`data'price`depvar') 			  	///
				event_var(last_sal_mw_event_rel_months6) 					///
				controls(`controls') window(6)								///
				absorb(`CFE') cluster(`cluster_se')
			graph export "`outstub'/last_`data'`depvar'_w6_cfe_with-control-units.png", replace	
		}
	}
end

main
