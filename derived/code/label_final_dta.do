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
	*clean date
	gen     year_month = date(date, "YMD")
	replace year_month = mofd(year_month)
	format  year_month %tm

	order year_month, after(date)
	drop date

	drop if missing(year_month)
	drop if missing(zipcode)

	* Remove obs with no data on minimum wage
	bys zipcode (year_month): egen no_mw_data = min(actual_mw)
	bys zipcode (year_month): egen no_mw_data_smallb = min(actual_mw_smallbusiness)
	drop if missing(no_mw_data)  
	drop if missing(no_mw_data) & missing(no_mw_data_smallb)	
	drop no_mw_data no_mw_data_smallb 

	*clean place/city name: since city has no missing keep that (BUT ZIP CODE CAN BELONG TO DIFFERENT CITIES!!!!!)
	* als, there are some 70000s zipcode-date where placename and city doesn't match (why)
	drop placename
	local dropwords = `" " Town$" "^Town of " " Township$" "'
		foreach w in `dropwords' {
			replace city = regexr(city, "`w'", "")
	}
end

program create_vars
	bysort zipcode (year_month): gen trend = _n

	local mw_type `" "" "_smallbusiness" "'
	foreach var_type in `mw_type' {
		bysort zipcode (year_month): gen dpct_actual_mw`var_type' = dactual_mw`var_type'/actual_mw`var_type'[_n-1]

		gen event_month`var_type' = mw_event`var_type' == 1
		sort zipcode year_month
		replace event_month`var_type' = 1 if year_month != year_month[_n-1] + 1  // zipcode changes

		gen event_month`var_type'_id = sum(event_month`var_type')

		bysort event_month`var_type'_id: gen months_since`var_type' = _n - 1
		bysort event_month`var_type'_id: gen months_until`var_type' = _N - months_since`var_type'

		bysort event_month`var_type'_id: replace months_until`var_type' = 0 if _N == months_until`var_type'

		drop event_month`var_type'_id event_month`var_type'		
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

	local mw_type `" "" "_smallbusiness" "'
	foreach var_type in `mw_type' {
		label var months_since`var_type' "Months since last MW`var_type' change"
		label var months_until`var_type' "Months until next MW`var_type' change"
	}

	order zipcode county countyfips msa city state* year_month 						    ///
		actual_mw* dactual_mw* mw_event* months_since* months_until*		///
		local_abovestate* county_abovestate* local_mw* county_mw* state_mw fed_mw
	xtset zipcode year_month
end 

main
