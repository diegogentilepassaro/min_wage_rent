set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado
adopath + ../../../lib/stata/mental_coupons/ado

program main
	local instub  "../temp"
	local outstub "../temp"

	import delim `instub'/data_clean.csv, delim(",")

	clean_vars
	gen_vars

	compress
	save_data `outstub'/zipcode_yearmonth_panel.dta, key(zipcode year_month) ///
		log(none) replace
end

program clean_vars

	gen year_month = date(date, "YMD")
	gen calendar_month = month(year_month)
	drop date
	replace year_month = mofd(year_month)
	format  year_month %tm

	keep if !missing(year_month)
	keep if !missing(zipcode)
	
	rename msa msa_str
	encode msa_str, gen(msa)
	drop msa_str
	
	replace dactual_mw = round(dactual_mw, 0.01)
	replace dactual_mw = 0 if dactual_mw < 0
end

program gen_vars

	bysort zipcode (year_month): gen trend = _n

	local mw_types `" "" "_smallbusiness" "'
	foreach var_type in `mw_types' {

		gen event_month`var_type' = mw_event`var_type' == 1
		replace event_month`var_type' = 1 if year_month != year_month[_n-1] + 1  // zipcode changes

		gen event_month`var_type'_id = sum(event_month`var_type')

		bysort event_month`var_type'_id: gen months_since`var_type' = _n - 1
		bysort event_month`var_type'_id: gen months_until`var_type' = _N - months_since`var_type'

		bysort event_month`var_type'_id: replace months_until`var_type' = 0 if _N == months_until`var_type'

		drop event_month`var_type'_id event_month`var_type'        
	}
	
	gen sal_mw_event = (dactual_mw >= 0.5)
	gen mw_event025  = (dactual_mw >= 0.25)
	gen mw_event075  = (dactual_mw >= 0.75)
end

main
