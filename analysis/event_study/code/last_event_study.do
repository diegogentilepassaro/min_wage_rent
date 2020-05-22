clear all
set more off
adopath + ../../../lib/stata/mental_coupons/ado
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main

	foreach window in 6 12 {
		use "../temp/baseline_rent_panel_`window'.dta", clear
		foreach depvar in medrentprice_sfcc medrentprice_mfr5plus ///
		    medrentprice_2br medrentpricepsqft_sfcc ///
			medrentpricepsqft_mfr5plus medrentpricepsqft_2br {
			
			create_event_plot, depvar(`depvar') 			  	///
				event_var(last_sal_mw_event_rel_months`window') ///
			    controls("i.cumul_nbr_unused_mw_events") window(`window')	///
			    absorb(zipcode calendar_month#countyfips year_month#statefips) cluster(zipcode)
			graph export "../output/`depvar'_last_sal_mw_event_rel_months`window'.png", replace	
		}
	}
	
	use "../temp/baseline_rent_panel_6.dta", clear
	create_event_plot, depvar(medrentpricepsqft_sfcc) 			  	///
		event_var(last_sal_mw_event_rel_months6) ///
		controls("i.cumul_nbr_unused_mw_events") window(6)	///
		absorb(zipcode year_month) cluster(zipcode)
	graph export "../output/two_way_last_medrentpricepsqft_sfcc6.png", replace
	
	foreach window in 6 12 {
		use "../temp/baseline_listing_panel_`window'.dta", clear
		foreach depvar in medlistingprice_sfcc medlistingprice_low_tier ///
	        medlistingprice_top_tier medlistingpricepsqft_sfcc ///
		    medlistingpricepsqft_low_tier medlistingpricepsqft_top_tier {
		
			create_event_plot, depvar(`depvar') 			  	///
				event_var(last_sal_mw_event_rel_months`window') ///
			    controls("i.cumul_nbr_unused_mw_events") window(`window')	///
			    absorb(zipcode calendar_month#countyfips year_month#countyfips) cluster(zipcode)
			graph export "../output/`depvar'_last_sal_mw_event_rel_months`window'.png", replace	

		}
end

main
