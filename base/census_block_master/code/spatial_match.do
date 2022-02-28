clear all
set more off
adopath + ../../../lib/stata/min_wage/ado

program main
    local in_shp    "../../../drive/base_large/shp_to_dta"
    local in_xwalk  "../../../drive/raw_data/census_crosswalks"
	local in_hud    "../../../drive/raw_data/hud_crosswalks"
    local temp      "../temp"
    local outstub   "../../../drive/base_large/census_block_master"
    local logfile   "../output/data_file_manifest.log"
    
    clean_zcta_tract_xwalk, instub(`in_xwalk')
    save_data "`temp'/tract_to_zcta.dta", log(none) ///
        key(statefips countyfips census_tract) replace 
    
    clean_zcta_cbsa_xwalk, instub(`in_xwalk')
    save_data "`temp'/zcta_to_cbsa.dta", log(none) ///
        key(zcta) replace 
		
    clean_tract_usps_zip_xwalk, instub(`in_hud')
    save_data "`temp'/tract_to_usps_zip.dta", log(none) ///
        key(statefips countyfips census_tract) replace 
    
    use "`in_shp'/census_blocks_2010_centroids_coord.dta", clear
    rename _ID     cb_centroid_geo_id
    rename (_X _Y) (longitude latitude)
    
    merge m:1 cb_centroid_geo_id using "`in_shp'/census_blocks_2010_centroids_db.dta", ///
        keep(1 3) nogen
    rename (statfps   cntyfps    cnss_tr      cnss_bl      nm_hs10     cnt_wn_          ) ///
           (statefips countyfips census_tract census_block num_house10 centroid_own_poly)
    replace countyfips = statefips + countyfips
    
    map_to_usps_zipcode, instub(`in_shp')    
    map_to_place,        instub(`in_shp')
    drop latitude longitude 

    merge m:1 statefips countyfips census_tract using "`temp'/tract_to_zcta.dta", ///
        keep(1 3) nogen
    merge m:1 zcta using "`temp'/zcta_to_cbsa.dta", ///
        keep(1 3) nogen
    merge m:1 statefips countyfips census_tract using "`temp'/tract_to_usps_zip.dta", ///
        keep(1 3) nogen

	gen missing_zipcode = (missing(zipcode))
	replace zipcode = zipcode_hud if missing_zipcode == 1
    
    gen rural = (missing(place_code))

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

program clean_zcta_cbsa_xwalk
    syntax, instub(str)
    
    import delimited "`instub'/zcta_cbsa.txt", ///
        clear stringcols(1 2)

    gen  neg_hupt = -hupt
    bysort zcta (neg_hupt): keep if _n == 1
    drop neg_hupt
    
    keep zcta5 cbsa
    rename (zcta5 cbsa) ///
           (zcta  cbsa10)  
end

program clean_tract_usps_zip_xwalk
    syntax, instub(str)
    
    import excel "`instub'/TRACT_ZIP_032010.xlsx", ///
        firstrow clear
    keep TRACT ZIP RES_RATIO
    rename (TRACT ZIP RES_RATIO) ///
	    (census_tract zipcode_hud res_ratio) 
		   
    gen neg_res_ratio = -res_ratio
    bysort census_tract (neg_res_ratio): keep if _n == 1
    drop neg_res_ratio res_ratio
	
	gen statefips = substr(census_tract, 1, 2) 
	gen countyfips = substr(census_tract, 1, 5) 
	replace census_tract = substr(census_tract, 6, .)
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

    drop us_place_poly_geo_id
end


main
