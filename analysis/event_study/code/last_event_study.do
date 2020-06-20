clear all
set more off
adopath + ../../../lib/stata/mental_coupons/ado
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../temp"
	local outstub "../output"

	local controls "i.cumsum_unused_events"
	local FE "zipcode year_month c.trend#i.countyfips c.trend_sq#i.countyfips"
	local cluster_se "statefips"

	foreach w in 6 {
		use "`instub'/baseline_rent_panel_`w'.dta", clear

		foreach depvar in _sfcc _2br _mfr5plus psqft_sfcc psqft_2br psqft_mfr5plus { 
			
			create_event_plot, depvar(medrentprice`depvar') 			  	///
				event_var(last_sal_mw_event_rel_months`w') 					///
			    controls(`controls') window(`w')							///
			    absorb(`FE') cluster(`cluster_se')
			graph export "`outstub'/last_rent`depvar'_w`w'.png", replace	
		}
	}
	
	use "`instub'/baseline_rent_panel_6.dta", clear
	create_event_plot, depvar(medrentpricepsqft_sfcc) 			  			///
		event_var(last_sal_mw_event_rel_months6) 							///
		controls(`controls') window(6)										///
		absorb(zipcode year_month) cluster(`cluster_se')
	graph export "../output/two_way_last_medrentpricepsqft_sfcc6.png", replace
	

	foreach w in 6 {
		use "`instub'/baseline_listing_panel_`w'.dta", clear
		foreach depvar in 	_sfcc 		_low_tier 		_top_tier 			///
		    				psqft_sfcc 	psqft_low_tier 	psqft_top_tier {
		
			create_event_plot, depvar(medlistingprice`depvar') 			  	///
				event_var(last_sal_mw_event_rel_months`w') 					///
			    controls(`controls') window(`w')							///
			    absorb(`FE') cluster(`cluster_se')
			graph export "`outstub'/last_listing`depvar'_w`w'.png", replace	
		}
	}
end

main
