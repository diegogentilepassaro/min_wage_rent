clear all
set more off
adopath + ../../../lib/stata/mental_coupons/ado
adopath + ../../../lib/stata/gslab_misc/ado
set maxvar 32000 

program main
    foreach data in rent listing {
	    foreach window in 2 4 {
		use "../../../drive/derived_large/output/baseline_`data'_county_quarter.dta", clear 
		    create_latest_event_vars, event_dummy(sal_mw_event) window(`window')                ///
			    time_var(year_quarter) geo_unit(countyfips) panel_end(2019q4)
				
	        drop if missing(last_sal_mw_event_rel_quarters`window')
			
	        save_data "../temp/baseline_`data'_county_quarter_`window'.dta", ///
			    key(countyfips year_quarter) replace log(none)
			}
	}
end

program create_latest_event_vars
	syntax, event_dummy(str) window(int) time_var(str) ///
	    geo_unit(str) panel_end(str)

	local window_span = `window'*2 + 1 

	gen `event_dummy'_`time_var' = `time_var' if `event_dummy' == 1
	format `event_dummy'_`time_var' %tq

	gen quarters_until_panel_ends = `=tq(`panel_end')' - year_quarter
	
	preserve
	keep if quarters_until_panel_ends >= (`window' + 1)
	collapse (max) last_`event_dummy'_`time_var' = `event_dummy'_`time_var', by(`geo_unit')
	format last_`event_dummy'_`time_var' %tq
	keep `geo_unit' last_`event_dummy'_`time_var'
	save_data "../temp/last_event`window'_by_`geo_unit'.dta", key(`geo_unit') replace
	restore
	
	merge m:1 `geo_unit' using "../temp/last_event`window'_by_`geo_unit'.dta", ///
	    nogen assert(3) keep(3)
	
	gen last_`event_dummy'_rel_quarters`window' = `time_var' - last_`event_dummy'_`time_var'
	replace last_`event_dummy'_rel_quarters`window' = last_`event_dummy'_rel_quarters`window' + `window' + 1
	replace last_`event_dummy'_rel_quarters`window' = 0 ///
	    if last_`event_dummy'_rel_quarters`window' <= 0
	replace last_`event_dummy'_rel_quarters`window' = 1000 ///
	    if (last_`event_dummy'_rel_quarters`window' > `window_span' & ///
		!missing(last_`event_dummy'_rel_quarters`window'))
	
	gen unused_mw_event`window' = (mw_event == 1 & last_`event_dummy'_rel_quarters`window' != (`window' + 1))
	bysort `geo_unit' (`time_var'): gen cumul_nbr_unused_mw_events = sum(unused_mw_event`window')
		
	drop `event_dummy'_`time_var' last_`event_dummy'_`time_var'    
end

main
