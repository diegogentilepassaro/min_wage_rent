set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local in_base        "../../../base/pennington/output"
    local instub_geo     "../../../base/geo_master/output"
    local in_derived_large "../../../drive/derived_large"
    local logfile        "../output/data_file_manifest.log"

	use "`instub_geo'/zip_county_place_usps_master.dta", clear
	clean_place_county_names
	save "../temp/geo_master_ca.dta", replace
	
    import delimited "`in_base'/clean_pennington_bay_area.csv", clear
	save "../temp/clean_pennington_bay_area.dta", replace
	
	keep nhood city
	duplicates drop nhood city, force
	gen pennington_geo_id = _n
	save "../temp/pennington_geos.dta", replace

	reclink nhood city using "../temp/clean_pennington_bay_area.dta", ///
	    gen(score) idmaster(pennington_geo_id) idusing(post_id)
	assert score == 1
	drop score _merge U*
	save "../temp/clean_pennington_bay_area.dta", replace
	
	use "../temp/pennington_geos.dta", clear
    reclink nhood using "../temp/geo_master_ca.dta", ///
	    gen(score) idmaster(pennington_geo_id) idusing(zipcode) ///
		uvar(place_name)	
	keep if _merge == 3
	drop _merge
	keep if score >= 0.99
	merge m:m pennington_geo_id using "../temp/clean_pennington_bay_area.dta", ///
	    nogen keep(3)
	duplicates drop post_id, force
	merge m:1 zipcode year month using "`in_derived_large'/min_wage/zip_statutory_mw.dta", ///
	    keep(1 3) keepusing(actual* binding*) nogen
    merge m:1 zipcode year month using "`in_derived_large'/min_wage/zipcode_experienced_mw.dta", ///
        nogen keep(1 3) keepusing(exp*)
	
	save_data "../output/clean_pennington_with_zipcode.dta", ///
	    key(post_id) log(`logfile') replace
end

program clean_place_county_names
    keep if state_abb == "CA"
	gen place_name_new = subinstr(place_name, ", CA", "", .)
	replace place_name = place_name_new
	drop place_name_new
	gen place_name_new = subinstr(place_name, " city", "", .)
	replace place_name = place_name_new
	drop place_name_new
	gen place_name_new = subinstr(place_name, " City", "", .)
	replace place_name = place_name_new
	drop place_name_new
	gen place_name_new = subinstr(place_name, "CDP", "", .)
	replace place_name = place_name_new
	drop place_name_new
	gen place_name_new = lower(place_name)
	replace place_name = place_name_new
	drop place_name_new
	
	replace place_name = place_name + " city" if ///
	    inlist(place_name, "daly", "foster", "redwood", "suisun", "union")

    gen county_name_new = subinstr(county_name, " CA", "", .)
	replace county_name = county_name_new
	drop county_name_new
	gen county_name_new = lower(county_name)
	replace county_name = county_name_new
	drop county_name_new
end

main
