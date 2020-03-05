clear all
set more off
adopath + ../../lib/stata/mental_coupons/ado

program main
	local instub  "../../derived/output/"
	local outstub "../output/"

	import delim `instub'data_clean.csv, clear

	prepare_data

	*plot_average, depvar(`rent2br_median') indepvar(`mw_change_event_date')
end

program prepare_data

	rename date date_string
	gen daily_date   = date(date_string, "YMD")
	gen year_month = mofd(daily_date)
	format year_month %tm
    	
	bysort zipcode: egen alo_event_min = max(min_event)
	*bysort zipcode: egen alo_event_mean = max(mean_event)
	*bysort zipcode: egen alo_event_max = max(max_event)
	
	keep if alo_event_min == 1
	gen event_min_month = year_month if min_event == 1
	bysort zipcode (year_month): carryforward event_min_month, replace
	
	gen neg_year_month = -year_month
	bysort zipcode (neg_year_month): carryforward event_min_month, gen(back_event_min_month)
	
	bysort zipcode: egen nbr_event_min = sum(min_event)
	
	gen min_event_non_overlapping = min_event
	local window 12
	
	forvalues i = 1:12 {
		replace min_event_non_overlapping = 0 if min_event[_n -`i'] == 1
	}
	
	*relative_time, num_periods(6) time(year_month) event_date()
end

/*program create_dep_var
	syntax, mw_var(str) time_frame(int)
	local mw_var "mean_actual_mw"
	bysort zipcode date: gen mw_change = (d`mw_var' != 0 & !missing(d`mw_var'))
	bysort zipcode date: gen mw_change_date = monthly_date if mw_change == 1
	local time_frame 10
	gen mw_change_event = (mw_change == 1)

	forvalues i = 1/`time_frame' {
		replace mw_change_event = 1 if mw_change[_n-`i'] == 1 & zipcode == zipcode[_n-`i']
		replace mw_change_event = 1 if mw_change[_n+`i'] == 1 & zipcode == zipcode[_n+`i']
	}
	local time_frame 10
	gen mw_change_event_date = 0 if mw_change == 1
	forvalues i = 1/`time_frame' {
		replace mw_change_event_date = mw_change_date[_n-`i'] - monthly_date             ///
							if mw_change[_n-`i'] == 1
		replace mw_change_event_date = monthly_date - mw_change_date[_n+`i']             ///
							if mw_change[_n+`i'] == 1
	}
end*/

program relative_time
syntax, num_periods(int) time(str) event_date(str)
	if "`time'" == "anio_sem" {
		gen t = `time' - hofd(`event_date')
	}
	else {
		gen t = `time' - yofd(`event_date')
	}
	replace t = -1000    if t < -`num_periods'
	replace t = 1000 if t >  `num_periods'
	replace t = t + `num_periods' + 1 if (t != -1000 & t != 1000)
	replace t = 0 if t == -1000
	assert !mi(t)
	tab t, m
end

main
