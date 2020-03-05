clear all
set more off
adopath + ../../lib/stata/mental_coupons/ado

program main
	local instub  "../../derived/output/"
	local outstub "../output/"

	import delim `instub'data_clean.csv, clear

	prepare_data
	create_dep_var, mw_var("mean_actual_mw") time_frame(10)

	plot_average, depvar(`rent2br_median') indepvar(`mw_change_event_date')
end

program prepare_data

	rename date date_string
	gen daily_date   = date(date_string, "YMD")
	gen monthly_date = month(daily_date)
end

program create_dep_var
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
end

main
