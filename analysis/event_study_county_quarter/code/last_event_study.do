clear all
set more off
adopath + ../../../lib/stata/mental_coupons/ado
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	foreach window in 2 4 {
		foreach depvar in medrentprice_sfcc medrentpricepsqft_sfcc{
			create_event_plot, depvar(`depvar') 			  	///
				event_var(last_sal_mw_event_rel_quarters`window') ///
				controls(" ") window(`window')	///
				absorb(countyfips year_quarter) cluster(countyfips)
			graph export "../output/`depvar'_last_sal_mw_event_rel_quarters`window'.png", replace
			
			create_event_plot if above == 0, depvar(`depvar') 			  	///
				event_var(last_sal_mw_event_rel_quarters`window') ///
				controls(" ") window(`window')	///
				absorb(countyfips year_quarter) cluster(countyfips)
			graph export "../output/`depvar'_last_sal_mw_event_rel_quarters`window'_low.png", replace
			
			create_event_plot if above == 1, depvar(`depvar') 			  	///
				event_var(last_sal_mw_event_rel_quarters`window') ///
				controls(" ") window(`window')	///
				absorb(countyfips year_quarter) cluster(countyfips)
			graph export "../output/`depvar'_last_sal_mw_event_rel_quarters`window'_high.png", replace
		}
	}
	
	foreach window in 2 4 {
		use "../temp/baseline_listing_county_quarter_`window'.dta", clear
		foreach depvar in medlistingprice_sfcc medlistingpricepsqft_sfcc {
		
			create_event_plot, depvar(`depvar') 			  	///
				event_var(last_sal_mw_event_rel_quarters`window') ///
				controls(" ") window(`window')	///
				absorb(countyfips year_quarter) cluster(countyfips)
			graph export "../output/`depvar'_last_sal_mw_event_rel_quarters`window'.png", replace
			
			create_event_plot if above == 0, depvar(`depvar') 			  	///
				event_var(last_sal_mw_event_rel_quarters`window') ///
				controls(" ") window(`window')	///
				absorb(countyfips year_quarter) cluster(countyfips)
			graph export "../output/`depvar'_last_sal_mw_event_rel_quarters`window'_low.png", replace
			
			create_event_plot if above == 1, depvar(`depvar') 			  	///
				event_var(last_sal_mw_event_rel_quarters`window') ///
				controls(" ") window(`window')	///
				absorb(countyfips year_quarter) cluster(countyfips)
			graph export "../output/`depvar'_last_sal_mw_event_rel_quarters`window'_high.png", replace

		}
	}
end

main

