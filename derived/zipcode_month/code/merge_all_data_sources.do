set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/mental_coupons/ado

program main
	local instub  "../../../drive/derived_large/min_wage"
	local outstub "../output"

	use "`instub'/zip_statutory_mw.dta"
    merge 1:1 zipcode year month using "`instub'/zip_experienced_mw.dta"

	gen_vars

	compress
	save_data `outstub'/zipcode_yearmonth_panel.dta, key(zipcode year_month) ///
		log(none) replace
end

program gen_vars
	drop year_month
	gen day = 1
	gen date = mdy(month, day, year)
	gen year_month = mofd(date)
	format year_month %tm
	drop day date
	
	qui sum year_month
	gen trend = year_month - r(min) + 1
	gen trend_sq = trend^2
	gen trend_cu = trend^3

	xtset zipcode year_month
	gen d_actual_mw = D.actual_mw
	gen mw_event = (d_actual_mw > 0)
	
	gen event_month = mw_event == 1
	replace event_month = 1 if year_month != year_month[_n-1] + 1  // zipcode changes
	gen event_month_id = sum(event_month)

	bysort event_month_id: gen months_since = _n - 1
	bysort event_month_id: gen months_until = _N - months_since
	bysort event_month_id: replace months_until = 0 if _N == months_until
	drop event_month_id event_month        
	
	gen sal_mw_event = (d_actual_mw >= 0.5)
	gen mw_event025  = (d_actual_mw >= 0.25)
	gen mw_event075  = (d_actual_mw >= 0.75)
end

main
