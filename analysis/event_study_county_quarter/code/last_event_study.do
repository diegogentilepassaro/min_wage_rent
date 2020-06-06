clear all
set more off
adopath + ../../../lib/stata/mental_coupons/ado
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	local instub "../temp"
	local outstub "../output"

	local FE "countyfips year_quarter"
	local cluster_se "countyfips"

	foreach w in 2 4 {
		foreach depvar in _sfcc psqft_sfcc{
			use "`instub'/baseline_rent_county_quarter_`w'.dta", clear

			create_event_plot, depvar(medrentprice`depvar') 				///
				event_var(last_sal_mw_event_rel_quarters`w') 				///
				controls(" ") window(`w')									///
				absorb(`FE') cluster(`cluster_se')
			graph export "`outstub'/last_rent`depvar'_w`w'.png", replace
			
			create_event_plot if above == 0, depvar(medrentprice`depvar')	///
				event_var(last_sal_mw_event_rel_quarters`w')				///
				controls(" ") window(`w')									///
				absorb(`FE') cluster(`cluster_se')
			graph export "`outstub'/last_rent`depvar'_w`w'_low.png", replace
			
			create_event_plot if above == 1, depvar(medrentprice`depvar')	///
				event_var(last_sal_mw_event_rel_quarters`w')				///
				controls(" ") window(`w')									///
				absorb(`FE') cluster(`cluster_se')
			graph export "`outstub'/last_rent`depvar'_w`w'_high.png", replace
		}
	}
	
	foreach w in 2 4 {
		use "`instub'/baseline_listing_county_quarter_`w'.dta", clear

		foreach depvar in _sfcc psqft_sfcc {
		
			create_event_plot, depvar(medlistingprice`depvar')				///
				event_var(last_sal_mw_event_rel_quarters`w')				///
				controls(" ") window(`w')									///
				absorb(`FE') cluster(`cluster_se')
			graph export "`outstub'/last_listing`depvar'_w`w'.png", replace
			
			create_event_plot if above == 0, depvar(medlistingprice`depvar')	///
				event_var(last_sal_mw_event_rel_quarters`w')					///
				controls(" ") window(`w')										///
				absorb(`FE') cluster(`cluster_se')
			graph export "`outstub'/last_listing`depvar'_w`w'_low.png", replace
			
			create_event_plot if above == 1, depvar(medlistingprice`depvar')	///
				event_var(last_sal_mw_event_rel_quarters`w')					///
				controls(" ") window(`w')										///
				absorb(`FE') cluster(`cluster_se')
			graph export "`outstub'/last_listing`depvar'_w`w'_high.png", replace

		}
	}
end

main

