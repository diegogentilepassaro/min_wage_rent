clear all
set more off
adopath + ../../../lib/stata/mental_coupons/ado
adopath + ../../../lib/stata/gslab_misc/ado
set maxvar 32000 

program main
    foreach data in rent listing {
	    foreach window in 6 12 {
		use "../../../drive/derived_large/output/baseline_`data'_panel.dta", clear
		    create_latest_event_vars, event_dummy(mw_event025) window(`window')                ///
			    time_var(year_month) geo_unit(zipcode) panel_end(2019m12)
	        create_latest_event_vars, event_dummy(mw_event075) window(`window')                ///
			    time_var(year_month) geo_unit(zipcode) panel_end(2019m12)

	        save_data "../temp/baseline_`data'_panel_`window'.dta", key(zipcode year_month)            ///
	            replace log(none)
			}
	}
end

program create_latest_event_vars
	syntax, event_dummy(str) window(int) time_var(str) ///
	    geo_unit(str) panel_end(str)
	
	local window_span = `window'*2 + 1 

	gen `event_dummy'_`time_var' = `time_var' if `event_dummy' == 1
	format `event_dummy'_`time_var' %tm

	cap gen months_until_panel_ends = `=tm(`panel_end')' - year_month
	
	preserve
	keep if months_until_panel_ends >= (`window' + 1)
	collapse (max) last_`event_dummy'_`time_var' = `event_dummy'_`time_var', by(`geo_unit')
	format last_`event_dummy'_`time_var' %tm
	keep `geo_unit' last_`event_dummy'_`time_var'
	save_data "../temp/last_event`window'_by_`geo_unit'.dta", key(`geo_unit') replace
	restore
	
	merge m:1 `geo_unit' using "../temp/last_event`window'_by_`geo_unit'.dta", ///
	    nogen assert(3) keep(3)
	
	gen last_`event_dummy'_rel_months`window' = `time_var' - last_`event_dummy'_`time_var'
	replace last_`event_dummy'_rel_months`window' = last_`event_dummy'_rel_months`window' + `window' + 1
	replace last_`event_dummy'_rel_months`window' = 0 ///
	    if last_`event_dummy'_rel_months`window' <= 0
	replace last_`event_dummy'_rel_months`window' = 1000 ///
	    if (last_`event_dummy'_rel_months`window' > `window_span' & ///
		!missing(last_`event_dummy'_rel_months`window'))
	
	gen unused_mw_event`event_dummy'_`window' = ///
	    (mw_event == 1 & last_`event_dummy'_rel_months`window' != (`window' + 1))
	bysort `geo_unit' (`time_var'): gen c_nbr_unused_`event_dummy'_`window' = ///
	    sum(unused_mw_event`event_dummy'_`window')
		
	drop `event_dummy'_`time_var' last_`event_dummy'_`time_var'
end

main
