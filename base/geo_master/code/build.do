set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
	local xwalk_dir  "../../../raw/crosswalk"
	local output     "../output"

	build_geomaster_large, instub(`xwalk_dir') outstub(`output')
	build_geomaster_small, instub(`xwalk_dir') outstub(`output')
end

program build_geomaster_large
	syntax, instub(str) outstub(str)
	import excel "`instub'/zip_to_zcta_2019.xlsx", ///
		sheet("ZiptoZCTA_crosswalk") firstrow allstring clear
	rename (ZIP_CODE ZCTA PO_NAME) (zipcode zcta zipcode_name)
	drop if zipcode == "96898" & zcta == "No ZCTA"
	keep zipcode zcta zipcode_name
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
		cbsa10_name state_abb
	order zcta zipcode place_code countyfips cbsa10 statefips ///
		houses_zcta_place_county zcta_name place_name county_name ///
		cbsa10_name state_abb

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
