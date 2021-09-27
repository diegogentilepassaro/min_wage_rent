set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
	local in_base          "../../../drive/base_large/pennington"
	local in_geo           "../../../base/geo_master/output"
	local in_derived_large "../../../drive/derived_large"
	local outstub         "../../../drive/derived_large/pennington"
	local logfile          "../output/data_file_manifest.log"

	make_california_geos, instub(`in_geo')
	save "../temp/geo_master_ca.dta", replace
	
	make_penningtion_geos, instub(`in_base')
	save "../temp/clean_pennington_bay_area.dta", replace
	
	gen_matched_geos

	merge m:m pennington_geo_id using "../temp/clean_pennington_bay_area.dta", ///
		nogen keep(3)
	duplicates drop post_id, force
	
	merge m:1 zipcode year month using "`in_derived_large'/min_wage/zip_statutory_mw.dta", ///
		keep(1 3) keepusing(actual* binding*) nogen
	merge m:1 zipcode year month using "`in_derived_large'/min_wage/zipcode_experienced_mw.dta", ///
		nogen keep(1 3) keepusing(exp*)
	
	save_data "`outstub'/clean_pennington_with_zipcode.dta", ///
		key(post_id) log(`logfile') replace
end

program make_california_geos
	syntax, instub(str)
	
	use "`instub'/zip_county_place_usps_master.dta", clear

	keep if state_abb == "CA"

	replace place_name = subinstr(place_name, ", CA", "", .)
	replace place_name = subinstr(place_name, " city", "", .)
	replace place_name = subinstr(place_name, " City", "", .)
	replace place_name = subinstr(place_name, "CDP", "", .)
	
	replace place_name = lower(place_name)
	replace place_name = place_name + " city" ///
		if inlist(place_name, "daly", "foster", "redwood", "suisun", "union")
	replace place_name = strltrim(place_name)
	
	replace county_name = subinstr(county_name, " CA", "", .)
	replace county_name = lower(county_name)
	
	drop if cbsa10 == "31100"
end

program make_penningtion_geos
	syntax, instub(str)

	import delimited "`instub'/clean_pennington_bay_area.csv", clear
	save "../temp/clean_pennington_bay_area.dta", replace
	
	keep nhood city
	duplicates drop nhood city, force
	gen pennington_geo_id = _n
	save "../temp/pennington_geos.dta", replace

	* Test reclink
	reclink nhood city using "../temp/clean_pennington_bay_area.dta", ///
		gen(score) idmaster(pennington_geo_id) idusing(post_id)
	assert score == 1
	drop score _merge U*
	save "../temp/clean_pennington_bay_area.dta", replace
end

program gen_matched_geos
	syntax, [thresh(real 0.9)]

	use "../temp/pennington_geos.dta", clear
	reclink nhood using "../temp/geo_master_ca.dta", ///
		gen(score) idmaster(pennington_geo_id) idusing(zipcode) ///
		uvar(place_name)
	keep if _merge == 3
	drop _merge
		
	keep if score >= `thresh' & nhood != "fairfax"   // fairfax is matched to fairfield
end


main
