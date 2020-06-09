clear all
set more off
adopath + ../../../lib/stata/gslab_misc/ado
set maxvar 32000 

program main
	local instub  "../../../drive/derived_large/output"
	local outstub "../temp"
	local logfile "../output/panels_data_file_manifest.log"

	foreach data in rent listing {
		foreach window in 12 24 {
			foreach kind in last all {
				* foreach kind in last nonoverlap all
				use "`instub'/baseline_`data'_panel.dta", clear

				create_event_dummy_vars, event_dummy(sal_mw_event) kind(`kind') w(`window')	///
					time_var(year_month) geo_unit(zipcode) w_control(6)
		
				save_data "`outstub'/`kind'_`data'_panel_`window'.dta",						///
					key(zipcode year_month) replace log(`logfile')
			}
		}
	}
end

program create_event_dummy_vars
	syntax, event_dummy(str) kind(str) w(int) time_var(str) geo_unit(str) w_control(int)

	bysort `geo_unit' (`time_var'): gen months_until_end = _N - _n

	if "`kind'" == "last" {
		gen_last_event_dummy, event_dummy(`event_dummy') time_var(`time_var') w(`w') 	///
			geo_unit(`geo_unit')
	}
	else if "`kind'" == "all" {
		gen all_`event_dummy' = `event_dummy'
		bysort `geo_unit' (`time_var'): replace all_`event_dummy' = 0 					///
			if months_until_end <= `w' // Ignore events without complete post
	}
	else if "`kind'" == "nonoverlap" {
		gen_nonoverlap_event_dummy, event_dummy(`event_dummy') time_var(`time_var') 	///
			w(`w') geo_unit(`geo_unit')
	}

	drop months_until_end

	gen_event_dummies, event_dummy(`kind'_`event_dummy') w(`w') 						///
		time_var(`time_var') geo_unit(`geo_unit')

	gen_control_event_dummies, all_events(mw_event) used_events(`kind'_`event_dummy')	///
		w(`w_control') time_var(`time_var') geo_unit(`geo_unit')
end

program gen_last_event_dummy
	syntax, event_dummy(str) w(str) time_var(str) geo_unit(str)

	bysort `geo_unit' (`time_var'): gen     event_count = sum(`event_dummy')
	bysort `geo_unit' (`time_var'): replace event_count = 0 if months_until_end <= `w' // Ignore events without complete post

	bysort `geo_unit'			  : egen event_max   = max(event_count)

	replace event_count = . if `event_dummy' == 0 | event_max == 0 // Account for zipcodes with 0 last events
	bysort `geo_unit' (`time_var'): gen last_`event_dummy' = event_count == event_max

	drop event_count event_max
end

program gen_event_dummies
	syntax, event_dummy(str) w(int) time_var(str) geo_unit(str)
	
	** gen event id, last and first mw
	gen 	event_month = `event_dummy' == 1
	replace event_month = 1 if `time_var' != `time_var'[_n-1] + 1  // zipcode changes

	gen 	event_month_id = sum(event_month)

	bysort `geo_unit' (`time_var'): egen last_mw_event  = max(event_month_id)
	bysort `geo_unit' (`time_var'): egen first_mw_event = min(event_month_id)

	bysort `geo_unit' (`time_var'): replace `event_dummy' = 0 if (`event_dummy' == 1) & ///
		(_N - _n + 1 <= `w' + 1 | _n <= `w' + 1) /// Ignore events without complete window

	** Create dummies
	gen d_0 = `event_dummy'
	local dummies "d_0"

	quietly levelsof `time_var'
	local num_periods = `r(r)' - `w'

	*forvalues i = 1/`w' {
	forvalues i = 1/`num_periods' {
		* Imputes missing at edge of panel
		bysort `geo_unit' (`time_var'): gen d_neg`i' = d_0[_n + `i']
		bysort `geo_unit' (`time_var'): gen d_`i'    = d_0[_n - `i']
		* Fixes edges of panel
		replace d_neg`i' = 0 if missing(d_neg`i')
		replace d_`i'    = 0 if missing(d_`i')

		*local dummies "d_neg`i' `dummies' d_`i'"
	}
	*egen some_dummy  = rowmax(`dummies')

	* Add increasing off_window dummies
/* 	bysort `geo_unit' (`time_var'): gen event_start = `event_dummy'[_n + `w']
	replace event_start = 0 if missing(event_start)
	bysort `geo_unit' (`time_var'): gen event_count = sum(event_start)
	bysort `geo_unit' (`time_var'): gen event_end = `event_dummy'[_n - `w' - 1]
	replace event_end = 0 if missing(event_end)
	bysort `geo_unit' (`time_var'): gen event_count_end = sum(event_end)
	quietly levelsof event_count
	local end = `r(r)'-1
	forvalues num = 1/`end'{
		gen d_off_`num'_1 = (event_count      < `num') & (!some_dummy)
		gen d_off_`num'_2 = (event_count_end >= `num') & (!d_off_`num'_1) & (!some_dummy)
	}
	bysort `geo_unit' (`time_var'): replace d_off_1_1 = 1 if last_mw_event == first_mw_event /// If no events turn on off windown dummy */

	drop event_month event_month_id first_mw_event last_mw_event
		*event_start event_end event_count event_count_end
end

program gen_control_event_dummies
	syntax, all_events(str) used_events(str) w(int) time_var(str) geo_unit(str)

	gen unused_event = `all_events' & !`used_events'

	bysort `geo_unit' (`time_var'): gen cum_unused_mw_events = sum(unused_event)

	months_since_and_until, event_dummy(unused_event)

	bysort `geo_unit' (`time_var'): gen unused_event_PRE  = months_until <= `w'
	bysort `geo_unit' (`time_var'): gen unused_event_POST = months_since <= `w'

	replace unused_event_PRE  = 0 if unused_event

	** Fix edges of panel
	bysort `geo_unit' (`time_var'): egen last_mw_event = max(cum_unused_mw_events)
	bysort `geo_unit' (`time_var'): egen first_mw_event = min(cum_unused_mw_events)

	bysort `geo_unit' (`time_var'): replace unused_event_PRE  = 0 if last_mw_event  == cum_unused_mw_events
	bysort `geo_unit' (`time_var'): replace unused_event_POST = 0 if first_mw_event == cum_unused_mw_events

	drop first_mw_event last_mw_event months_since months_until
end

program months_since_and_until
	syntax, event_dummy(str)

	gen event_month = `event_dummy' == 1
	replace event_month = 1 if year_month != year_month[_n-1] + 1  // zipcode changes

	gen event_month_id = sum(event_month)

	bysort event_month_id: gen months_since = _n - 1

	bysort event_month_id: gen months_until = _N - months_since

	drop event_month event_month_id
end

main
