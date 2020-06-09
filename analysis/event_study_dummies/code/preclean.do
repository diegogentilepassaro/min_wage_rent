clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
set maxvar 32000 

program main
	local instub  "../../../drive/derived_large/output"
	local outstub "../temp"
	local logfile "../output/panels_data_file_manifest.log"

	foreach data in rent listing {
		foreach window in 6 12 {
			foreach kind in last all {
				* foreach kind in last nonoverlap all
				use "`instub'/baseline_`data'_panel.dta", clear

				create_event_dummy_vars, event_dummy(sal_mw_event) kind(`kind') w(`window')	///
					time(year_month) geo(zipcode) w_control(6)
		
				drop_vars_with_all_zero

				save_data "`outstub'/`kind'_`data'_panel_`window'.dta",						///
					key(zipcode year_month) replace log(`logfile')
			}
		}
	}
end

program create_event_dummy_vars
	syntax, event_dummy(str) kind(str) w(int) time(str) geo(str) w_control(int)

	bysort `geo' (`time'): gen months_until_end = _N - _n

	if "`kind'" == "last" {
		gen_last_event_dummy, event_dummy(`event_dummy') time(`time') w(`w') 	///
			geo(`geo')
	}
	else if "`kind'" == "all" {
		gen all_`event_dummy' = `event_dummy'
		bysort `geo' (`time'): replace all_`event_dummy' = 0 					///
			if months_until_end <= `w' // Ignore events without complete post
	}

	drop months_until_end

	gen_control_event_dummies, all_events(mw_event) used_events(`kind'_`event_dummy')	///
		w(`w_control') time(`time') geo(`geo')
		
	gen_event_dummies, event_dummy(`kind'_`event_dummy') w(`w') 						///
		time(`time') geo(`geo')
end

program gen_last_event_dummy
	syntax, event_dummy(str) w(str) time(str) geo(str)

	bysort `geo' (`time'): gen     event_count = sum(`event_dummy')
	bysort `geo' (`time'): replace event_count = 0 if months_until_end <= `w' // Ignore events without complete post

	bysort `geo': egen last_event = max(event_count)

	replace event_count = -100 if `event_dummy' == 0 | last_event == 0 // Account for zipcodes with 0 last events
	bysort `geo' (`time'): gen last_`event_dummy' = event_count == last_event

	drop event_count last_event
end

program gen_event_dummies
	syntax, event_dummy(str) w(int) time(str) geo(str)
	
	
	* Ignore events without complete post or pre window
	bysort `geo' (`time'): replace `event_dummy' = 0 if (`event_dummy' == 1) & ///
														(_N - _n + 1 <= `w' + 1 | _n <= `w' + 1) 
	** gen event id, last and first mw											
	gen 	event_month = `event_dummy' == 1
	replace event_month = 1 if `time' != `time'[_n-1] + 1  // zipcode changes

	gen 	event_month_id = sum(event_month)

	bysort `geo' (`time'): egen last_mw_event  = max(event_month_id)
	bysort `geo' (`time'): egen first_mw_event = min(event_month_id)

	** Create dummies
	gen d_0 = `event_dummy'
	local dummies "d_0"

	quietly levelsof `time'
	local num_periods = `r(r)' - `w'

	forvalues i = 1/`num_periods' {
		quietly{
			* Imputes missing at edge of panel
			bysort `geo' (`time'): gen d_neg`i' = d_0[_n + `i']
			bysort `geo' (`time'): gen d_`i'    = d_0[_n - `i']
			* Fixes edges of panel
			replace d_neg`i' = 0 if missing(d_neg`i')
			replace d_`i'    = 0 if missing(d_`i')
		}
	}

	drop event_month event_month_id first_mw_event last_mw_event
end

program gen_control_event_dummies
	syntax, all_events(str) used_events(str) w(int) time(str) geo(str)

	gen unused_event = `all_events' & !`used_events'

	bysort `geo' (`time'): gen cum_unused_mw_events = sum(unused_event)


	* Doesn't work. The pre of an event is the post of another, so it's confusing and unclear how to deal with this
	/* 
	bysort `geo' (`time'): egen last_mw_event  = max(cum_unused_mw_events)
	bysort `geo' (`time'): egen first_mw_event = min(cum_unused_mw_events)

	months_since_and_until, event_dummy(unused_event)

	bysort `geo' (`time'): gen unused_event_PRE  = months_until <= `w'
	bysort `geo' (`time'): gen unused_event_POST = months_since <= `w'

	replace unused_event_PRE  = 0 if unused_event

	bysort `geo' (`time'): gen unused_event_PRE_1 = months_until > `w'
	bysort `geo' (`time'): gen unused_event_POST_1 = months_since > `w'

	** Fix edges of panel

	bysort `geo' (`time'): replace unused_event_PRE  = 0 if last_mw_event  == cum_unused_mw_events
	bysort `geo' (`time'): replace unused_event_POST = 0 if first_mw_event == cum_unused_mw_events

	bysort `geo' (`time'): replace unused_event_PRE_1  = 0 if last_mw_event  == cum_unused_mw_events
	bysort `geo' (`time'): replace unused_event_POST_1 = 0 if first_mw_event == cum_unused_mw_events

	drop first_mw_event last_mw_event months_since months_until 
	*/
end

program months_since_and_until
	syntax, event_dummy(str)

	quietly {
		gen event_month = `event_dummy' == 1
		replace event_month = 1 if year_month != year_month[_n-1] + 1  // zipcode changes

		gen event_month_id = sum(event_month)

		bysort event_month_id: gen months_since = _n - 1

		bysort event_month_id: gen months_until = _N - months_since

		drop event_month event_month_id
	}
end

program drop_vars_with_all_zero
	
	ds, has(type numeric)
	local varlist `"`r(varlist)'"'

	foreach var of local varlist {
		qui sum `var'
		if (r(min) == 0) & (r(max) == 0) {
			qui drop `var'
			
			// just to keep a record of which
			// variable got dropped
			local dropped `"`dropped' `var'"'
		}
	}
	di "Variables dropped: `dropped'"
end

main
