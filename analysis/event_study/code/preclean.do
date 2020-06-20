clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
set maxvar 32000 

program main
	local instub "../../../drive/derived_large/output"
	local outstub "../temp"

	foreach data in rent listing {
		foreach w in 6 {
			use "`instub'/baseline_`data'_panel.dta", clear
			
			create_latest_event_vars, event_dummy(sal_mw_event) w(`w') 		///
				time(year_month) geo(zipcode) panel_end(2019m12)

			gen treated = (!missing(last_sal_mw_event_rel_months`w'))
			replace last_sal_mw_event_rel_months = 20000 if missing(last_sal_mw_event_rel_months`w')
		
			save_data "`outstub'/baseline_`data'_panel_`w'.dta", 			///
				key(zipcode year_month) replace log(none)
		}
	}
end

program create_latest_event_vars
	syntax, event_dummy(str) w(int) time(str) geo(str) panel_end(str)
	
	local window_span = `w'*2 + 1 

	gen `event_dummy'_`time' = `time' if `event_dummy' == 1
	format `event_dummy'_`time' %tm

	gen months_until_panel_ends = `=tm(`panel_end')' - `time'

	preserve
		keep if months_until_panel_ends >= (`w' + 1)
		collapse (max) last_`event_dummy'_`time' = `event_dummy'_`time', by(`geo')

		format last_`event_dummy'_`time' %tm
		keep `geo' last_`event_dummy'_`time'

		save_data "../temp/last_event`w'_by_`geo'.dta", key(`geo') replace
	restore
	
	merge m:1 `geo' using "../temp/last_event`w'_by_`geo'.dta", 						///
		nogen assert(3) keep(3)
	
	gen last_`event_dummy'_rel_months`w' = `time' - last_`event_dummy'_`time'
	replace last_`event_dummy'_rel_months`w' = last_`event_dummy'_rel_months`w' + `w' + 1
	
	replace last_`event_dummy'_rel_months`w' = 0 										///
				if last_`event_dummy'_rel_months`w' <= 0
	replace last_`event_dummy'_rel_months`w' = 1000 									///
				if (last_`event_dummy'_rel_months`w' > `window_span' & 					///
				!missing(last_`event_dummy'_rel_months`w'))
	
	gen unused_mw_event`w' = (mw_event == 1 & last_`event_dummy'_rel_months`w' != (`w' + 1))
	bysort `geo' (`time'): gen cumsum_unused_events = sum(unused_mw_event`w')
		
	drop `event_dummy'_`time' last_`event_dummy'_`time'    
end

main
