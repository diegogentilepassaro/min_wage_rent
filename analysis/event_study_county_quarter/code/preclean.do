clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
set maxvar 32000 

program main
	local instub  "../../../drive/derived_large/output"
	local outstub "../temp"

	foreach data in rent listing {
		foreach window in 2 4 {
			use "`instub'/baseline_`data'_county_quarter.dta", clear 
			
			create_latest_event_vars, event_dummy(sal_mw_event) w(`window')			///
				time(year_quarter) geo(countyfips) panel_end(2019q4)
			
			save_data "`outstub'/baseline_`data'_county_quarter_`window'.dta",		///
				key(countyfips year_quarter) replace log(none)
		}
	}
end

program create_latest_event_vars
	syntax, event_dummy(str) w(int) time(str) geo(str) panel_end(str)
	
	local window_span = `w'*2 + 1 

	gen `event_dummy'_`time' = `time' if `event_dummy' == 1
	format `event_dummy'_`time' %tm

	gen quarters_until_panel_ends = `=tq(`panel_end')' - year_quarter
	
	preserve
		keep if quarters_until_panel_ends >= (`w' + 1)
		collapse (max) last_`event_dummy'_`time' = `event_dummy'_`time', by(`geo')
		
		format last_`event_dummy'_`time' %tq
		keep `geo' last_`event_dummy'_`time'

		save_data "../temp/last_event`w'_by_`geo'.dta", key(`geo') replace
	restore
	
	merge m:1 `geo' using "../temp/last_event`w'_by_`geo'.dta", 					///
		nogen assert(3) keep(3)
	
	gen last_`event_dummy'_rel_quarters`w' = `time' - last_`event_dummy'_`time'
	replace last_`event_dummy'_rel_quarters`w' = last_`event_dummy'_rel_quarters`w' + `w' + 1
	
	gen treated = !missing(last_`event_dummy'_rel_quarters`w')

	replace last_`event_dummy'_rel_quarters`w' = 0						/// 0 is pre-period
				if last_`event_dummy'_rel_quarters`w' <= 0 & treated
	replace last_`event_dummy'_rel_quarters`w' = 1000						/// 1000 is post-period
				if last_`event_dummy'_rel_quarters`w' > `window_span' & treated
	replace last_`event_dummy'_rel_quarters`w' = 5000	if !treated			/// 5000 means never treated
	
	gen unused_mw_event`w' = (mw_event == 1 & last_`event_dummy'_rel_quarters`w' != (`w' + 1))
	bysort `geo' (`time'): gen cumsum_unused_events = sum(unused_mw_event`w')

	drop `event_dummy'_`time' last_`event_dummy'_`time'  
end

main
