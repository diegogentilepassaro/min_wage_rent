set more off
clear all
adopath + ../../lib/stata/gslab_misc/ado
adopath + ../../lib/stata/mental_coupons/ado

cap mkdir "../output/"


program main 
	local csv_data "../output/"
	local temp "../temp/"

	import_csv, instub(`csv_data')
	clean_vars
	label_vars

	local output "../output/"
	compress
	save_data `output'data_ready.dta, key(year_month zipcode) replace
end 

program import_csv
	syntax, instub(str)
	import delim `instub'data_clean.csv, delim(",")
end 

program clean_vars
	*clean date
	g year_month = date(date, "YMD")
	replace year_month = mofd(year_month)
	format year_month %tm 
	order year_month, after(date)
	drop date 

	drop if missing(year_month)

	* Remove obs with no data on minimum wage 
	bys zipcode (year_month): egen no_mw_min_data = min(min_actual_mw)
	bys zipcode (year_month): egen no_mw_mean_data = min(mean_actual_mw)
	bys zipcode (year_month): egen no_mw_max_data = min(max_actual_mw)	
	drop if missing(no_mw_min_data) & missing(no_mw_mean_data) & missing(no_mw_max_data)	
	drop no_mw_min_data no_mw_mean_data no_mw_max_data

	*clean place/city name: since city has no missing keep that (BUT ZIP CODE CAN BELONG TO DIFFERENT CITIES!!!!!)
	* als, there are some 70000s zipcode-date where placename and city doesn't match (why)
	drop placename 
	local dropwords = `" " Town$" "^Town of " " Township$" "'
		foreach w in `dropwords' {
			replace city = regexr(city, "`w'", "")
	}

end


program label_vars 
	sort state county city zipcode year_month

	foreach var in city msa {
		encode `var', g(`var'2)
		order `var'2, after(`var')
		drop `var'
		rename `var'2 `var'
	}
	
	bysort state (statename): replace statename = statename[_N]
	labmask state, values(statename)
	drop statename 
	
	g countyfips = string(state, "%02.0f") + string(county, "%03.0f") 
	destring countyfips, replace force 
	order countyfips, after(county)
	labmask countyfips, values(countyname)
	drop countyname

	order placetype, after(stateabb)
	encode placetype, g(ptype2)
	order ptype2, after(placetype)
	drop placetype
	rename ptype2 placetype


	sort state county city zipcode year_month	

	tsset year_month zipcode
end 







main
