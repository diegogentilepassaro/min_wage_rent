clear all
set more off
adopath + ../../../lib/stata/min_wage/ado

program main
    local in_data   "../temp"
    local in_xwalk  "../../../drive/raw_data/census_crosswalks/"
    local outstub   "../../../drive/base_large/census_block_master"
    local logfile   "../output/data_file_manifest.log"
    
    clean_zcta_tract_xwalk, instub(`in_xwalk')
    save_data "`in_data'/tract_to_zcta.dta", log(none) ///
        key(statefips countyfips census_tract) replace 
    
    use "`in_data'/census_blocks_2010_centroids_coord.dta", clear
    rename _ID     cb_centroid_geo_id
    rename (_X _Y) (longitude latitude)
    
    merge m:1 cb_centroid_geo_id using "`in_data'/census_blocks_2010_centroids_db.dta", ///
        keep(1 3) nogen
    rename (statfps   cntyfps    cnss_tr      cnss_bl      nm_hs10    ) ///
           (statefips countyfips census_tract census_block num_house10)
    
    map_to_usps_zipcode, instub(`in_data')    
    map_to_place,        instub(`in_data')

    merge m:1 statefips countyfips census_tract using "`in_data'/tract_to_zcta.dta", ///
        keep(1 3) nogen

    save_data "`outstub'/census_block_master.dta", log(`logfile') ///
        key(census_block) replace
    export delimited "`outstub'/census_block_master.csv", replace
end

program clean_zcta_tract_xwalk
    syntax, instub(str)
    
    import delimited "`instub'/zcta_census_tract.txt", ///
        clear stringcols(1 2 3 4 5)

    gen  neg_hupt = -hupt
    bysort state county tract (neg_hupt): keep if _n == 1
    drop neg_hupt
    
    keep state county zcta5 tract
    replace county = state + county
    rename (state     county     zcta5 tract       ) ///
           (statefips countyfips zcta  census_tract)  
end

program map_to_usps_zipcode
    syntax, instub(str)

    geoinpoly latitude longitude ///
        using "`instub'/USPS_zipcodes_July2020_coord.dta"
    rename _ID usps_zip_poly_geo_id

    merge m:1 usps_zip_poly_geo_id using "`instub'/USPS_zipcodes_July2020_db.dta", ///
        keep(1 3) nogen keepusing(ZIP_CODE)
    rename ZIP_CODE zipcode

    drop usps_zip_poly_geo_id cb_centroid_geo_id
end

program map_to_place
    syntax, instub(str)

    geoinpoly latitude longitude ///
        using "`instub'/us_places_2010_coord.dta"
    rename _ID us_place_poly_geo_id

    merge m:1 us_place_poly_geo_id using "`instub'/us_places_2010_db.dta", ///
        keep(1 3) nogen keepusing(place_code place_name place_type)

    drop us_place_poly_geo_id latitude longitude    
end


main
