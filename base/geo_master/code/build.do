set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
	local xwalk_dir  "../../../raw/crosswalk"
	local zillow_dir  "../../../drive/base_large/zillow"
	local output     "../output"
    
	build_zillow_zipcode_stats, instub(`zillow_dir')
	build_geomaster_large, instub(`xwalk_dir') outstub(`output')
	build_geomaster_small, instub(`xwalk_dir') outstub(`output')
end

program build_zillow_zipcode_stats
    syntax, instub(str)
    use "`instub'/zillow_zipcode_clean.dta"
	keep if !missing(medrentpricepsqft_SFCC)
	collapse (count) nbr_months_with_zillow_rents = medrentpricepsqft_SFCC, by(zipcode)
    tostring zipcode, format(%05.0f) replace
	save "../temp/zillow_zipcodes_with_rents.dta", replace
end

program build_geomaster_large
	syntax, instub(str) outstub(str)
	import excel "`instub'/zip_to_zcta_2019.xlsx", ///
		sheet("ZiptoZCTA_crosswalk") firstrow allstring clear
	rename (ZIP_CODE ZCTA PO_NAME) (zipcode zcta zipcode_name)
	drop if zipcode == "96898" & zcta == "No ZCTA"
	keep zipcode zcta zipcode_name
	merge 1:1 zipcode using "../temp/zillow_zipcodes_with_rents.dta", ///
	    assert(1 3)
	gen zipcode_with_zillow_rents = (_merge == 3)
	replace nbr_months_with_zillow_rents = 0 if missing(nbr_months_with_zillow_rents)
	drop _merge
	save_data "../temp/usps_master.dta", ///
		key(zipcode) replace
	
	clear
	import delimited "`instub'/geocorr2018.csv", ///
		varnames(1) stringcols(1 2 3 4 5)
	drop metdiv10 mdivname10 afact
	rename (zcta5 placefp county state zipname cntyname placenm cbsaname10 stab) ///
		(zcta place_code countyfips statefips zcta_name county_name place_name ///
		cbsa10_name state_abb)
	rename hus10 houses_zcta_place_county
	merge m:m zcta using "../temp/usps_master.dta", nogen keep(3)

	keep zcta zipcode place_code countyfips cbsa10 statefips ///
		houses_zcta_place_county zcta_name place_name county_name ///
		cbsa10_name state_abb zipcode_with_zillow_rents nbr_months_with_zillow_rents
	order zcta zipcode place_code countyfips cbsa10 statefips ///
		houses_zcta_place_county zcta_name place_name county_name ///
		cbsa10_name state_abb zipcode_with_zillow_rents nbr_months_with_zillow_rents
    
    bysort zcta countyfips place_code: egen max_months_with_data = max(nbr_months_with_zillow_rents)
    keep if max_months_with_data == nbr_months_with_zillow_rents
	drop max_months_with_data
	duplicates tag zcta countyfips place_code, gen(dup)
	sum nbr_months_with_zillow_rents if dup >0 
	assert r(max) == 0
    duplicates drop zcta countyfips place_code, force
	replace nbr_months_with_zillow_rents = . if nbr_months_with_zillow_rents == 0

	save_data "`outstub'/zip_county_place_usps_master.dta", ///
		key(zcta zipcode countyfips place_code) replace
	save_data "`outstub'/zip_county_place_usps_master.csv", outsheet ///
		key(zcta zipcode countyfips place_code) replace
end

program build_geomaster_small
	syntax, instub(str) outstub(str)

	import excel "`instub'/TRACT_ZIP_122019.xlsx", ///
		firstrow clear

	drop BUS_RATIO OTH_RATIO TOT_RATIO	

	rename (TRACT ZIP RES_RATIO) (tract_fips zipcode res_ratio)

	save_data "`outstub'/tract_zip_master.dta", ///
		key(tract_fips zipcode) replace
	save_data "`outstub'/tract_zip_master.csv", outsheet ///
		key(tract_fips zipcode) replace
end 

*EXECUTE
main 
