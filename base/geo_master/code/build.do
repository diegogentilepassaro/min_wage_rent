set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local xwalk_dir  "../../../raw/crosswalk"
    local zillow_dir "../../../drive/base_large/zillow"
    local shape_dir  "../../../drive/raw_data/shapefiles/USPS_zipcodes"
    local output     "../output"
    
    build_geomaster_large, instub(`xwalk_dir') ///
	    in_shape(`shape_dir') outstub(`output')
    build_geomaster_small, instub(`xwalk_dir') ///
	    outstub(`output')
end

program build_geomaster_large
    syntax, instub(str) in_shape(str) outstub(str)
	
	import dbase "`in_shape'/USPS_zipcodes_July2020.dbf", clear
    rename (ZIP_CODE PO_NAME STATE POPULATION SQMI) ///
	    (zipcode zipcode_name statefips pop2020_esri area_sqmi)
	keep zipcode pop2020_esri area_sqmi
	save_data "../temp/usps_shape.dta", key(zipcode) replace log(none)

    import excel "`instub'/zip_to_zcta_2019.xlsx", ///
        sheet("ZiptoZCTA_crosswalk") firstrow allstring clear
    rename (ZIP_CODE ZCTA PO_NAME) (zipcode zcta zipcode_name)
    drop if zipcode == "96898" & zcta == "No ZCTA"
    keep zipcode zcta zipcode_name
    save_data "../temp/usps_master.dta", key(zipcode) replace log(none)
    
    import delimited "`instub'/geocorr2018.csv", ///
        varnames(1) stringcols(1 2 3 4 5) clear

    drop metdiv10 mdivname10 afact
    rename (zcta5      county       placefp     state)                  ///
           (zcta       countyfips   place_code  statefips)
    rename (zipname    cntyname     placenm     cbsaname10   stab)      ///
           (zcta_name  county_name  place_name  cbsa10_name  state_abb)
    rename hus10 houses_zcta_place_county

    gen rural = place_code == "99999"

    merge m:m zcta using "../temp/usps_master.dta", nogen keep(3)

    * Make sure zipcode-county-place combinations are unique
    isid zipcode place_code countyfips

    local keep_vars ///
    	zipcode     place_code   countyfips   cbsa10     zcta       ///
        place_name  county_name  cbsa10_name  state_abb  statefips  ///
        houses_zcta_place_county rural

    keep  `keep_vars'
    order `keep_vars'
	
	merge m:1 zipcode using "../temp/usps_master.dta", nogen keep(1 3)
	
	replace place_code = "47766" if zipcode == "95035" /* Manual fix for Milpitas*/
	
	save_data "`outstub'/zip_county_place_usps_all.dta", ///
        key(zipcode countyfips place_code) replace
    export delimited "`outstub'/zip_county_place_usps_all.csv", replace
	
    gen   neg_houses = -houses_zcta_place_county
    bys   zipcode (neg_houses): keep if _n == 1
    drop  neg_houses		
	
    save_data "`outstub'/zip_county_place_usps_master.dta", ///
        key(zipcode) replace
    export delimited "`outstub'/zip_county_place_usps_master.csv", replace
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
