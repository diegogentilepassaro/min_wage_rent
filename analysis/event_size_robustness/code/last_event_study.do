clear all
set more off
adopath + ../../../lib/stata/mental_coupons/ado
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/min_wage/ado
set maxvar 32000 

program main

	foreach window in 12 24 {
		use "../temp/baseline_rent_panel_`window'.dta", clear
			
	    create_event_plot, depvar(medrentpricepsqft_sfcc) 			  	///
			event_var(last_mw_event025_rel_months`window') ///
			controls(" ") window(`window')	///
			absorb(zipcode calendar_month year_month) cluster(zipcode) ///
			name(rent025, replace) ytitle("Median rent per square foot - SFCC")
			
        create_event_plot, depvar(dactual_mw) 			  	///
			event_var(last_mw_event025_rel_months`window') ///
			controls(" ") window(`window')	///
			absorb(zipcode calendar_month year_month) cluster(zipcode) ///
			name(deltamw025, replace) ytitle("Change in minimum wage")
			
		graph combine rent025 deltamw025, row(2) col(1) ///
		    graphregion(color(white)) ysize(20) xsize(12) ///
			title("MW changes of at least $0.25")
	    graph export "../output/rent_last_mw_event025_rel_months`window'.png", replace
		
	    create_event_plot, depvar(medrentpricepsqft_sfcc) 			  	///
			event_var(last_mw_event075_rel_months`window') ///
			controls(" ") window(`window')	///
			absorb(zipcode calendar_month year_month) cluster(zipcode) ///
			name(rent075, replace) ytitle("Median rent per square foot - SFCC")
			
        create_event_plot, depvar(dactual_mw) 			  	///
			event_var(last_mw_event075_rel_months`window') ///
			controls(" ") window(`window')	///
			absorb(zipcode calendar_month year_month) cluster(zipcode) ///
			name(deltamw075, replace) ytitle("Change in minimum wage")
			
		graph combine rent075 deltamw075, row(2) col(1) ///
		    graphregion(color(white)) ysize(20) xsize(12)  ///
			title("MW changes of at least $0.75")
	    graph export "../output/rent_last_mw_event075_rel_months`window'.png", replace
		
		use "../temp/baseline_listing_panel_`window'.dta", clear
		
        create_event_plot, depvar(medlistingpricepsqft_sfcc) 			  	///
			event_var(last_mw_event025_rel_months`window') ///
			controls(" ") window(`window')	///
			absorb(zipcode calendar_month year_month) cluster(zipcode) ///
			name(listing025, replace) ytitle("Median listing price per square foot - SFCC")
			
        create_event_plot, depvar(dactual_mw) 			  	///
			event_var(last_mw_event025_rel_months`window') ///
			controls(" ") window(`window')	///
			absorb(zipcode calendar_month year_month) cluster(zipcode) ///
			name(deltamw025_listing, replace) ytitle("Change in minimum wage")
			
		graph combine listing025 deltamw025_listing, row(2) col(1) ///
		    graphregion(color(white)) ysize(20) xsize(12)  ///
			title("MW changes of at least $0.25")
	    graph export "../output/listing_last_mw_event025_rel_months`window'.png", replace
		
	    create_event_plot, depvar(medlistingpricepsqft_sfcc) 			  	///
			event_var(last_mw_event075_rel_months`window') ///
			controls(" ") window(`window')	///
			absorb(zipcode calendar_month year_month) cluster(zipcode) ///
			name(listing075, replace) ytitle("Median listing price per square foot - SFCC")
			
        create_event_plot, depvar(dactual_mw) 			  	///
			event_var(last_mw_event075_rel_months`window') ///
			controls(" ") window(`window')	///
			absorb(zipcode calendar_month year_month) cluster(zipcode) ///
			name(deltamw075_listing, replace) ytitle("Change in minimum wage")
			
		graph combine listing075 deltamw075_listing, row(2) col(1) ///
		    graphregion(color(white)) ysize(20) xsize(12)  ///
			title("MW changes of at least $0.75")
	    graph export "../output/listing_last_mw_event075_rel_months`window'.png", replace
	}
end

main
