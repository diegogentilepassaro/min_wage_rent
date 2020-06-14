clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../temp"
	local outstub "../output"

	local controls "i.cumsum_unused_events"
	local CFE "countyfips year_month c.trend#i.countyfips c.trend_sq#i.countyfips c.trend_cu#i.countyfips"
	local ZFE "zipcode year_month c.trend#i.countyfips c.trend_sq#i.countyfips c.trend_cu#i.countyfips"
	local cluster_se "statefips"

	use "`instub'/baseline_rent_panel_6.dta" if treated == 1, clear

	foreach depvar in psqft_sfcc { 
		
		create_event_plot, depvar(medrentprice`depvar') 			  	///
			event_var(last_sal_mw_event_rel_months6) 					///
			controls(`controls') window(6)							///
			absorb(`CFE') cluster(`cluster_se')
		graph export "`outstub'/last_rent_cfe_`depvar'_w6.png", replace	
	}
	
	foreach depvar in psqft_sfcc { 
		
		create_event_plot, depvar(medrentprice`depvar') 			  	///
			event_var(last_sal_mw_event_rel_months6) 					///
			controls(`controls') window(6)							///
			absorb(`ZFE') cluster(`cluster_se')
		graph export "`outstub'/last_rent_zfe_`depvar'_w6.png", replace	
	}	
	
	use "`instub'/baseline_listing_panel_6.dta" if treated == 1, clear
	foreach depvar in psqft_sfcc {
	
		create_event_plot, depvar(medlistingprice`depvar') 			  	///
			event_var(last_sal_mw_event_rel_months6) 					///
			controls(`controls') window(6)							///
			absorb(`CFE') cluster(`cluster_se')
		graph export "`outstub'/last_listing_cfe_`depvar'_w6.png", replace	
	}
	
	foreach depvar in psqft_sfcc {
	
		create_event_plot, depvar(medlistingprice`depvar') 			  	///
			event_var(last_sal_mw_event_rel_months6) 					///
			controls(`controls') window(6)							///
			absorb(`ZFE') cluster(`cluster_se')
		graph export "`outstub'/last_listing_zfe_`depvar'_w6.png", replace	
	}
end

main
