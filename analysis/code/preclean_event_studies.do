clear all
set more off
adopath + ../../lib/stata/mental_coupons/ado
adopath + ../../lib/stata/gslab_misc/ado
set maxvar 32000 

program main
	local instub  "../../derived/output/"
	local outstub "../output/"

	use `instub'zipcode_yearmonth_panel.dta, clear

	prepare_data, time_var(year_month) geo_unit(zipcode)

	foreach window in 12 24 {
		create_latest_event_vars, event_dummy(max_event) window(`window')                         ///
			time_var(year_month) geo_unit(zipcode)
			
        create_event_vars, event_dummy(max_event) window(`window')                         ///
			time_var(year_month) geo_unit(zipcode)
						
	}
	
	save_data ../temp/zipcode_year_month_panel.dta, key(zipcode year_month) ///
	    replace log(none)
end

program prepare_data
    syntax, time_var(str) geo_unit(str)

    gen date = dofm(year_month)
	gen calendar_month = month(date)
	drop date
	
	replace min_event = 0 if dmin_actual_mw < 0.5
	replace mean_event = 0 if dmean_actual_mw < 0.5
	replace max_event = 0 if dmax_actual_mw < 0.5


	drop if missing(msa)
	
	keep zipcode year_month state msa calendar_month ///
	    zhvi2br rent2br_median rent2br_psqft_median ///
		min_event mean_event max_event
end

program create_latest_event_vars
	syntax, event_dummy(str) window(int) time_var(str) geo_unit(str) [min_option(str)]
	
	local window_span = `window'*2 + 1 
	
	gen `event_dummy'_`time_var' = `time_var' if `event_dummy' == 1
	format `event_dummy'_`time_var' %tm
	
	bysort `geo_unit': egen last_`event_dummy'_`time_var' = max(`event_dummy'_`time_var')
	gen last_`event_dummy'_rel_months`window' = `time_var' - last_`event_dummy'_`time_var'
	replace last_`event_dummy'_rel_months`window' = last_`event_dummy'_rel_months`window' + `window' + 1
	replace last_`event_dummy'_rel_months`window' = 0 ///
	    if last_`event_dummy'_rel_months`window' <= 0
	replace last_`event_dummy'_rel_months`window' = 1000 ///
	    if last_`event_dummy'_rel_months`window' > `window_span'
		
	drop `event_dummy'_`time_var' last_`event_dummy'_`time_var'
end

program create_event_vars
	syntax, event_dummy(str) window(int) time_var(str) geo_unit(str)

	bysort `geo_unit' (`time_var'): gen event_start = 1 if `event_dummy'[_n + `window'] == 1
	gen event_start_non_overlap = event_start
	forvalues i = 0(1)`window' {  					
		bysort `geo_unit' (`time_var'): replace event_start_non_overlap = . ///
		    if `event_dummy'[_n - `i'] == 1
	}
	
	local window_span = 2*`window' + 1
	gen rel_months_`event_dummy' = event_start_non_overlap
	forvalues i = 2(1)`window_span' {  					
		bysort `geo_unit' (`time_var'): replace rel_months_`event_dummy' = `i' ///
		    if event_start_non_overlap[_n - `i' + 1] == 1
	}
	replace rel_months_`event_dummy' = 1000 if rel_months_`event_dummy' == .


	drop event_start event_start_non_overlap
	rename rel_months_`event_dummy' rel_months_`event_dummy'`window'	
end

main
