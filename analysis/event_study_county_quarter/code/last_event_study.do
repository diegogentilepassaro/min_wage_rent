clear all
set more off
adopath + ../../../lib/stata/mental_coupons/ado
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../temp"
	local outstub "../output"

	local FE 		"countyfips year_quarter"
	local FE_trend 	"countyfips year_quarter c.trend#i.countyfips c.trend_sq#i.countyfips"
	local cluster_se "countyfips"
	local controls 	"i.cumsum_unused_events"

	foreach w in 2 4 {
		foreach depvar in _sfcc psqft_sfcc{
			use "`instub'/baseline_rent_county_quarter_`w'.dta", clear

			create_event_plot_with_untreated, depvar(medrentprice`depvar') 				///
				event_var(last_sal_mw_event_rel_quarters`w') 							///
				controls(`controls') window(`w')										///
				absorb(`FE') cluster(`cluster_se')
			graph export "`outstub'/last_rent`depvar'_w`w'.png", replace

			create_event_plot_with_untreated, depvar(medrentprice`depvar') 				///
				event_var(last_sal_mw_event_rel_quarters`w') 							///
				controls(`controls') window(`w')										///
				absorb(`FE_trend') cluster(`cluster_se')
			graph export "`outstub'/last_rent`depvar'_w`w'_trend.png", replace
			
			create_event_plot_with_untreated if above, depvar(medrentprice`depvar')		///
				event_var(last_sal_mw_event_rel_quarters`w')							///
				controls(`controls') window(`w')										///
				absorb(`FE') cluster(`cluster_se')
			graph export "`outstub'/last_rent`depvar'_w`w'_low.png", replace
			
			create_event_plot_with_untreated if !above, depvar(medrentprice`depvar')	///
				event_var(last_sal_mw_event_rel_quarters`w')							///
				controls(`controls') window(`w')										///
				absorb(`FE') cluster(`cluster_se')
			graph export "`outstub'/last_rent`depvar'_w`w'_high.png", replace
		}
	}
	
	foreach w in 2 4 {
		use "`instub'/baseline_listing_county_quarter_`w'.dta", clear

		foreach depvar in _sfcc psqft_sfcc {
			
			create_event_plot_with_untreated, depvar(medlistingprice`depvar')			///
				event_var(last_sal_mw_event_rel_quarters`w')							///
				controls(`controls') window(`w')										///
				absorb(`FE') cluster(`cluster_se')
			graph export "`outstub'/last_listing`depvar'_w`w'.png", replace
			
			create_event_plot_with_untreated, depvar(medlistingprice`depvar')			///
				event_var(last_sal_mw_event_rel_quarters`w')							///
				controls(`controls') window(`w')										///
				absorb(`FE') cluster(`cluster_se')
			graph export "`outstub'/last_listing`depvar'_w`w'_trend.png", replace

			create_event_plot_with_untreated if above, depvar(medlistingprice`depvar')	///
				event_var(last_sal_mw_event_rel_quarters`w')							///
				controls(`controls') window(`w')										///
				absorb(`FE') cluster(`cluster_se')
			graph export "`outstub'/last_listing`depvar'_w`w'_low.png", replace
			
			create_event_plot_with_untreated if !above, depvar(medlistingprice`depvar')	///
				event_var(last_sal_mw_event_rel_quarters`w')							///
				controls(`controls') window(`w')										///
				absorb(`FE') cluster(`cluster_se')
			graph export "`outstub'/last_listing`depvar'_w`w'_high.png", replace

		}
	}
end

main

