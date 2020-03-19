clear all
set more off
adopath + ../../lib/stata/mental_coupons/ado
adopath + ../../lib/stata/gslab_misc/ado
set maxvar 32000 

program main 
	local instub "../../derived/temp/"
	local outstu "../output/"

	import delim `instub'zillow_clean.csv, delim(",")

	prepare_zillow_data, time_var(year_month) geounit(zipcode)	




end 


program prepare_zillow_data
	syntax, time_var(str) geounit(str)

	replace date = date + "_01"
	gen     year_month = date(date, "YMD")
	replace year_month = mofd(year_month)
	format  year_month %tm
	order year_month, after(date)
	drop date 

	label_vars

	xtset `geounit' `time_var'
end


program label_vars 
	foreach var in city msa county {
		encode `var', g(`var'2)
		order `var'2, after(`var')
		drop `var'
		rename `var'2 `var'
	}
	
	bysort stateabb (statename): replace statename = statename[_N]
	bysort statename (stateabb): replace stateabb = stateabb[_N]

	statastates, abbreviation(stateabb) nogen 
	drop state_name
	rename state_fips state
	labmask state, values(statename)
	drop statename
	order state, before(stateabb) 

end 



































main 
