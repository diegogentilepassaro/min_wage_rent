set more off
clear all
adopath + ../../lib/stata/gslab_misc/ado
adopath + ../../lib/stata/mental_coupons/ado

cap mkdir "../output/"


program main 
	local csv_data "../output/"
	local output "../output/"
	local temp "../temp/"

	import_csv, instub(`csv_data') outstub(`output')

end 

program import_csv
	syntax, instub(str) outstub(str)

	import delim `instub'data_clean.csv, delim(",")
end 

program label_vars 
	
	*clean date
	g date2 = date(date, "YMD")
	replace date2 = ym(year(date2), month(date2))
	format date2 %tm 
	order date2, after(date)
	drop date 
	rename date2 date

	*clean place/city name: since city has no missing keep that (BUT ZIP CODE CAN BELONG TO DIFFERENT CITIES!!!!!)
	* als, there are some 70000s zipcode-date where placename and city doesn't match (why)
	drop placename 
	local dropwords = `" " Town$" "^Town of " " Township$" "'
		foreach w in `dropwords' {
			replace city = regexr(city, "`w'", "")
	}

	*clean county : no need 
	g countyfips = string(state, "%02.0f") + string(county, "%03.0f") 
	destring countyfips, replace 
	order countyfips, after(county)

	*clean state
	br if !missing(state) & missing(statename)

	bysort state (statename): replace statename = statename[_N]
	bysort stateabb (statename): replace statename = statename[_N]
	bysort stateabb (state): replace state = state[1] 

	drop stateabb 
	* make labels 
	sort state county city zipcode date

	foreach var in city msa {
		encode `var', g(`var'2)
		order `var'2, after(`var')
		drop `var'
		rename `var'2 `var'
	}

	labmask countyfips, values(countyname)

	bys countyfips (countyname): g diff = countyname[1]!= countyname[_N]
	br if diff

	foreach var in countyfips state {
		labmask `var', values(`var'name)
	}


	


end 







main
