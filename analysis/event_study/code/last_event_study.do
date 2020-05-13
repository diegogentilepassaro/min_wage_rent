clear all
set more off
adopath + ../../../lib/stata/mental_coupons/ado
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main
	foreach window in 12 24 {
		use "../temp/baseline_rent_panel_`window'.dta", clear

		create_event_plot, depvar(dactual_mw) 			  	///
			event_var(last_sal_mw_event_rel_months`window') ///
			controls(" ") window(`window')	///
			absorb(zipcode calendar_month year_month) cluster(zipcode) ///
			name(deltamw_rents, replace) ytitle("Change in minimum wage")
	    
		create_event_plot, depvar(medrentpricepsqft_sfcc) 			  	///
			event_var(last_sal_mw_event_rel_months`window') ///
			controls(" ") window(`window')	///
			absorb(zipcode calendar_month year_month) cluster(zipcode) ///
			name(rents, replace) ytitle("Median rent per square foot - SFCC")

	    graph combine rents deltamw_rents, row(2) col(1) ///
		    graphregion(color(white)) ysize(20) xsize(12) ///
			title("MW changes of at least $0.5")
		graph export "../output/rents_last_sal_mw_event_rel_months`window'.png", replace
		
		use "../temp/baseline_listing_panel_`window'.dta", clear

		create_event_plot, depvar(dactual_mw) 			  	///
			event_var(last_sal_mw_event_rel_months`window') ///
			controls(" ") window(`window')	///
			absorb(zipcode calendar_month year_month) cluster(zipcode) ///
			name(deltamw_listings, replace) ytitle("Change in minimum wage")
	    
		create_event_plot, depvar(medlistingpricepsqft_sfcc) 			  	///
			event_var(last_sal_mw_event_rel_months`window') ///
			controls(" ") window(`window')	///
			absorb(zipcode calendar_month year_month) cluster(zipcode) ///
			name(listings, replace) ytitle("Median listing price per square foot - SFCC")

	    graph combine listings deltamw_listings, row(2) col(1) ///
		    graphregion(color(white)) ysize(20) xsize(12) ///
			title("MW changes of at least $0.5")
		graph export "../output/listings_last_sal_mw_event_rel_months`window'.png", replace
	}

	foreach window in 12 24 {
		use "../temp/baseline_rent_panel_`window'.dta", clear
		foreach depvar in medrentprice_sfcc medrentprice_mfr5plus ///
		    medrentprice_2br ///
			medrentpricepsqft_mfr5plus medrentpricepsqft_2br {
			
			create_event_plot, depvar(`depvar') 			  	///
				event_var(last_sal_mw_event_rel_months`window') ///
				controls(" ") window(`window')	///
				absorb(zipcode calendar_month year_month) cluster(zipcode)
			graph export "../output/`depvar'_last_sal_mw_event_rel_months`window'.png", replace	
		}
	}
	
	foreach window in 12 24 {
		use "../temp/baseline_listing_panel_`window'.dta", clear
		foreach depvar in medlistingprice_sfcc medlistingprice_low_tier ///
	        medlistingprice_top_tier ///
		    medlistingpricepsqft_low_tier medlistingpricepsqft_top_tier {
		
			create_event_plot, depvar(`depvar') 			  	///
				event_var(last_sal_mw_event_rel_months`window') ///
				controls(" ") window(`window')	///
				absorb(zipcode calendar_month year_month) cluster(zipcode)
			graph export "../output/`depvar'_last_sal_mw_event_rel_months`window'.png", replace	

		}
	}
end

main
