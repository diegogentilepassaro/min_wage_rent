clear all
set more off
adopath + ../../../lib/stata/mental_coupons/ado
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main

	foreach window in 6 12 {
		use "../temp/baseline_rent_panel_`window'.dta", clear
			
	    create_event_plot, depvar(medrentpricepsqft_sfcc) 			  	///
			event_var(last_mw_event025_rel_months`window') ///
			controls("i.c_nbr_unused_mw_event025_`window'") window(`window')	///
			absorb(zipcode calendar_month#countyfips year_month#statefips) cluster(zipcode)
	    graph export "../output/rent_last_mw_event025_rel_months`window'.png", replace
		
	    create_event_plot, depvar(medrentpricepsqft_sfcc) 			  	///
			event_var(last_mw_event075_rel_months`window') ///
			controls("i.c_nbr_unused_mw_event075_`window'") window(`window')	///
			absorb(zipcode calendar_month#countyfips year_month#statefips) cluster(zipcode)
	    graph export "../output/rent_last_mw_event075_rel_months`window'.png", replace
		
		use "../temp/baseline_listing_panel_`window'.dta", clear
		
        create_event_plot, depvar(medlistingpricepsqft_sfcc) 			  	///
			event_var(last_mw_event025_rel_months`window') ///
			controls("i.c_nbr_unused_mw_event025_`window'") window(`window')	///
			absorb(zipcode calendar_month#countyfips year_month#countyfips) cluster(zipcode)
	    graph export "../output/listing_last_mw_event025_rel_months`window'.png", replace
		
	    create_event_plot, depvar(medlistingpricepsqft_sfcc) 			  	///
			event_var(last_mw_event075_rel_months`window') ///
			controls("i.c_nbr_unused_mw_event075_`window'") window(`window')	///
			absorb(zipcode calendar_month#countyfips year_month#countyfips) cluster(zipcode)
	    graph export "../output/listing_last_mw_event075_rel_months`window'.png", replace
	}
end

main
