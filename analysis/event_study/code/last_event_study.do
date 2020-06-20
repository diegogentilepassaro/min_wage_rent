clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../temp"
	local outstub "../output"

	local controls "i.cumsum_unused_events"
	local FE "zipcode year_month"
	local FE_trend "zipcode year_month c.trend#i.countyfips c.trend_sq#i.countyfips"
	local cluster_se "statefips"

	foreach w in 6 {
		use "`instub'/baseline_rent_panel_`w'.dta", clear

		foreach depvar in _sfcc _2br _mfr5plus psqft_sfcc psqft_2br psqft_mfr5plus { 
			
			create_event_plot_with_untreated, depvar(medrentprice`depvar') 		///
				event_var(last_sal_mw_event_rel_months`w') 						///
				controls(`controls') window(`w')								///
				absorb(`FE') cluster(`cluster_se')
			graph export "`outstub'/last_rent`depvar'_w`w'.png", replace	
		}

		create_event_plot_with_untreated, depvar(ln_rent_psqft) 				///
			event_var(last_sal_mw_event_rel_months`w') 							///
			controls(`controls') window(`w')										///
			absorb(`FE') cluster(`cluster_se')
		graph export "`outstub'/last_ln_rentpsqft_sfccw`w'.png", replace

		create_event_plot_with_untreated, depvar(medrentpricepsqft_sfcc) 		///
			event_var(last_sal_mw_event_rel_months`w') 							///
			controls(`controls') window(`w')										///
			absorb(`FE_trend') cluster(`cluster_se')
		graph export "`outstub'/last_rentpsqft_sfccw`w'_county-trend.png", replace
	}
	
	foreach w in 6 {
		use "`instub'/baseline_listing_panel_`w'.dta", clear
		foreach depvar in 	_sfcc 		_low_tier 		_top_tier 				///
							psqft_sfcc 	psqft_low_tier 	psqft_top_tier {

			create_event_plot_with_untreated, depvar(medlistingprice`depvar') 	///
				event_var(last_sal_mw_event_rel_months`w') 						///
				controls(`controls') window(`w')								///
				absorb(`FE') cluster(`cluster_se')
			graph export "`outstub'/last_listing`depvar'_w`w'.png", replace	
		}

		create_event_plot_with_untreated, depvar(ln_houseprice_psqft) 			///
			event_var(last_sal_mw_event_rel_months`w') 							///
			controls(`controls') window(`w')									///
			absorb(`FE') cluster(`cluster_se')
		graph export "`outstub'/last_listingpsqft_sfccw`w'_county-trend.png", replace

		create_event_plot_with_untreated, depvar(medlistingpricepsqft_sfcc) 	///
			event_var(last_sal_mw_event_rel_months`w') 							///
			controls(`controls') window(`w')									///
			absorb(`FE_trend') cluster(`cluster_se')
		graph export "`outstub'/last_listingpsqft_sfccw`w'_county-trend.png", replace
	}
end

main
