set more off
clear all
adopath + ../../lib/stata/gslab_misc/ado
adopath + ../../lib/stata/mental_coupons/ado

program main 
	local instub  "../../drive/derived_large/output"
	local oustub  "../../drive/derived_large/output"
	local logfile "../output/data_file_manifest.log"

	import delim `instub'/data_clean.csv, delim(",")

	clean_vars
	create_vars
	label_vars

	compress
	save_data `oustub'/zipcode_yearmonth_panel.dta, key(zipcode year_month) log(`logfile') replace
end 

program clean_vars
	gen     year_month = date(date, "YMD")
	gen calendar_month = month(year_month)
	replace year_month = mofd(year_month)
	format  year_month %tm
	order year_month, after(date)
	drop date

	drop if missing(year_month)
	drop if missing(zipcode)

	*clean place/city name: since city has no missing keep that (BUT ZIP CODE CAN BELONG TO DIFFERENT CITIES!!!!!)
	* also, there are some 70000s zipcode-date where placename and city doesn't match (why)
	drop placename
	local dropwords = `" " Town$" "^Town of " " Township$" "'
		foreach w in `dropwords' {
			replace city = regexr(city, "`w'", "")
	}
end

program create_vars
	foreach var_type in min mean max {
		bysort zipcode (year_month): gen dpct_`var_type'_actual_mw = d`var_type'_actual_mw/`var_type'_actual_mw[_n-1]

		gen `var_type'_event_month = `var_type'_event == 1
		replace `var_type'_event_month = 1 if year_month != year_month[_n-1] + 1  // zipcode changes

		gen `var_type'_event_month_id = sum(`var_type'_event_month)

		bysort `var_type'_event_month_id: gen months_since_`var_type' = _n - 1
		bysort `var_type'_event_month_id: gen months_until_`var_type' = _N - months_since_`var_type'

		bysort `var_type'_event_month_id: replace months_until_`var_type' = 0 if _N == months_until_`var_type'

		drop `var_type'_event_month_id `var_type'_event_month
	}
end

program label_vars 
	foreach var in city msa {
		encode `var', g(`var'2)
		order `var'2, after(`var')
		drop `var'
		rename `var'2 `var'
	}
	
	bysort state (statename): replace statename = statename[_N]
	labmask state, values(statename)
	drop statename 

	gen countyfips = string(state, "%02.0f") + string(county, "%03.0f") 
	destring countyfips, replace force 
	order countyfips, after(county)
	labmask countyfips, values(countyname)
	drop countyname

	order placetype, after(stateabb)
	encode placetype, g(ptype2)
	order ptype2, after(placetype)
	drop placetype
	rename ptype2 placetype

	foreach var_type in min mean max {
		label var months_since_`var_type' "Months since last MW change (`var_type'_event)"
		label var months_until_`var_type' "Months until next MW change (`var_type'_event)"
	}

	order zipcode county countyfips msa city state* year_month 						    ///
		min_actual_mw dmin_actual_mw min_event months_since_min months_until_min		///
		mean_actual_mw dmean_actual_mw mean_event months_since_mean months_until_mean	///
		max_actual_mw dmax_actual_mw max_event months_since_max months_until_max		///
		localabovestate countyabovestate *_local_mw *_county_mw *_state_mw *_fed_mw
	xtset zipcode year_month
end 

main
