set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main 
	local raw     "../../../drive/raw_data"
	local outstub "../output"
	local temp    "../temp"

	forval yr = 2012(1)2016 {
		prepare_12_16, raw(`raw') temp(`temp') yr(`yr')
	}

	use `temp'/safmrs_2012.dta, clear
	forval yr = 2013(1)2016 {
		append using `temp'/safmrs_`yr'.dta
	}

	save_data `outstub'/safrm_2012_2016_by_zipcode_county_cbsa10.dta, ///
		key(countyfips cbsa10 zipcode year) replace
	
	forval yr = 2017(1)2019 {
		prepare_17_19, raw(`raw') temp(`temp') yr(`yr')
	}
	
	use `temp'/safmrs_2017.dta, clear
	forval yr = 2018(1)2019 {
		append using `temp'/safmrs_`yr'.dta
	}

	save_data `outstub'/safrm_2017_2019_by_zipcode_cbsa10.dta, ///
		key(cbsa10 zipcode year) replace
end

program prepare_12_16
	syntax, raw(str) temp(str) yr(int)

	cap import excel `raw'/SFMR/fy`yr'_safmrs.xls, first clear case(lower)
	cap import excel `raw'/SFMR/fy`yr'_safmrs.xlsx, first clear case(lower)
	cap import excel `raw'/SFMR/fy`yr'_safmrs_rev.xlsx, first clear case(lower)

	cap rename zip zipcode
	cap rename zip_code zipcode
	
	cap rename state statefips
	cap gen countyfips = statefips + county
	
	cap tostring cbsa, gen(cbsa10)
	cap rename cbsamet cbsa10
	cap rename metro_code cbsa10
	cap rename area_rent_br* safmr*br
	
	gen year = `yr'
	
	drop if missing(zipcode)
	drop if missing(cbsa10)
	drop if missing(countyfips)

	sort cbsa10 countyfips zipcode year
	order cbsa10 countyfips zipcode year
	
	collapse (mean) safmr0br safmr1br safmr2br safmr3br safmr4br, ///
		by(countyfips cbsa10 zipcode year)
	
	keep countyfips cbsa10 zipcode year safmr0br ///
		safmr1br safmr2br safmr3br safmr4br
	save_data `temp'/safmrs_`yr'.dta, key(countyfips cbsa10 zipcode year) ///
		log(none) replace
end

program prepare_17_19
	syntax, raw(str) temp(str) yr(int)

	cap import excel `raw'/SFMR/fy`yr'_safmrs.xlsx, first clear case(lower)
	cap import excel `raw'/SFMR/fy`yr'_safmrs_rev.xlsx, first clear case(lower)
	
	cap rename zip zipcode
	cap rename zip_code zipcode
		
	cap rename metro_code cbsa10
	
	cap gen cbsa = substr(hudareacode, 1, 10)
	cap gen cbsa10 = subinstr(cbsa, "METRO", "", .)

	cap rename area_rent_br* safmr*br
	
	gen year = `yr'
	
	drop if missing(zipcode)
	drop if missing(cbsa10)

	sort cbsa10 zipcode year
	order cbsa10 zipcode year
		
	collapse (mean) safmr0br safmr1br safmr2br safmr3br safmr4br, ///
		by(cbsa10 zipcode year)

	keep cbsa10 zipcode year safmr0br ///
		safmr1br safmr2br safmr3br safmr4br
	save_data `temp'/safmrs_`yr'.dta, key(cbsa10 zipcode year) ///
		log(none) replace
end

* Execute
main
