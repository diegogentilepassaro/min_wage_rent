clear all
set more off
adopath + ../../../lib/stata/mental_coupons/ado
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../temp"
	local outstub "../output"

	local controls "i.treated i.cumsum_unused_events"
	local CFE "countyfips year_month c.trend#i.countyfips c.trend_sq#i.countyfips c.trend_cu#i.countyfips"
	local cluster_se "statefips"

	use "`instub'/baseline_rent_panel_6.dta", clear
	foreach depvar in psqft_sfcc { 
		
		create_event_plot, depvar(medrentprice`depvar') 			  	///
			event_var(last_sal_mw_event_rel_months6) 					///
			controls(`controls') window(6)							///
			absorb(`CFE') cluster(`cluster_se')
		graph export "`outstub'/last_rent_cfe_with_control_`depvar'_w6.png", replace	
	}
	
	use "`instub'/baseline_listing_panel_6.dta", clear
	foreach depvar in psqft_sfcc {
	
		create_event_plot, depvar(medlistingprice`depvar') 			  	///
			event_var(last_sal_mw_event_rel_months6) 					///
			controls(`controls') window(6)							///
			absorb(`CFE') cluster(`cluster_se')
		graph export "`outstub'/last_listing_cfe_with_control_`depvar'_w6.png", replace	
	}
end

main
