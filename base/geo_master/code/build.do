set more off
clear all
adopath + ../../../lib/stata/gslab_misc/ado

program main
    local xwalk_dir  "../../../raw/crosswalk"
    local zillow_dir "../../../drive/base_large/zillow"
    local output     "../output"
    
    build_zillow_zipcode_stats, instub(`zillow_dir')
    build_geomaster_large, instub(`xwalk_dir') outstub(`output')
    build_geomaster_small, instub(`xwalk_dir') outstub(`output')
end

program build_zillow_zipcode_stats
    syntax, instub(str)

    use "`instub'/zillow_zipcode_clean.dta"

    keep if !missing(medrentpricepsqft_SFCC)
    collapse (count) n_months_zillow_rents = medrentpricepsqft_SFCC, by(zipcode)
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

    gen zillow_zipcode = (_merge == 3)
    replace n_months_zillow_rents = 0 if missing(n_months_zillow_rents)
    drop _merge

    save_data "../temp/usps_master.dta", key(zipcode) replace log(none)
    
    clear
    import delimited "`instub'/geocorr2018.csv", ///
        varnames(1) stringcols(1 2 3 4 5)

    drop metdiv10 mdivname10 afact
    rename (zcta5  placefp     county      state)     ///
           (zcta   place_code  countyfips  statefips)
    rename (zipname    cntyname     placenm     cbsaname10   stab)      ///
           (zcta_name  county_name  place_name  cbsa10_name  state_abb)
    rename hus10 houses_zcta_place_county

    merge m:m zcta using "../temp/usps_master.dta", nogen keep(3)

    local keep_vars ///
    	zcta zipcode place_code countyfips cbsa10 statefips       ///
        houses_zcta_place_county zcta_name place_name county_name ///
        cbsa10_name state_abb zillow_zipcode n_months_zillow_rents

    keep  `keep_vars'
    order `keep_vars' 
    
    bys zcta countyfips place_code: egen max_months_with_data = max(n_months_zillow_rents)

    keep if max_months_with_data == n_months_zillow_rents
    drop max_months_with_data

    duplicates tag zcta countyfips place_code, gen(dup)
    sum n_months_zillow_rents if dup > 0
    assert r(max) == 0

    duplicates drop zcta countyfips place_code, force
    replace n_months_zillow_rents = . if n_months_zillow_rents == 0

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

    local instub  "../../../raw/crosswalk"
    import delim "`instub'/tract_zcta_xwalk.csv", ///
        varnames(1) stringcols(3 4 5) clear

    replace tract = tract * 100
    replace tract = round(tract, 1)     
    g tract_fips = string(tract, "%06.0f")
    g county_fips = string(county, "%05.0f")
    replace tract_fips = county_fips + tract_fips      
    order tract_fips, first

    rename (zcta5 afact) (zcta res_ratio)
    keep tract_fips zcta res_ratio

    save_data "`outstub'/tract_zcta_master.dta", ///
        key(tract_fips zcta) replace
    save_data "`outstub'/tract_zcta_master.csv", outsheet ///
        key(tract_fips zcta) replace   
end 

*EXECUTE
main 
