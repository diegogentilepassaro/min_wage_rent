clear all
set more off
adopath + ../../../lib/stata/min_wage/ado

program main
    local in_shp    "../../../drive/base_large/shp_to_dta"
	local in_hud    "../../../drive/raw_data/hud_crosswalks"
    local temp      "../temp"
    local outstub   "../../../drive/base_large/census_block_master"
    local logfile   "../output/data_file_manifest.log"
	
	clean_tract_usps_zip_xwalk, instub(`in_hud')
    save_data "`temp'/tract_to_usps_zip.dta", log(none) ///
        key(statefips countyfips tract) replace
		
    clean_centroids, instub(`in_shp')
    save_data "`temp'/centroids.dta", log(none) ///
        key(block) replace 

	import delimited "`temp'/cb_lodes_crosswalk.csv", ///
	    stringcols(_all) clear
	merge 1:1 block using "`temp'/centroids.dta", ///
        keep(1 3) nogen

    map_to_usps_zipcode, instub(`in_shp')    
    drop latitude longitude
		
	gen rural = (place_code == "9999999") if !missing(place_code)

    merge m:1 statefips countyfips tract using "`temp'/tract_to_usps_zip.dta", ///
        keep(1 3) nogen
	gen missing_zipcode = (missing(zipcode))
	replace zipcode = zipcode_hud if missing_zipcode == 1

    save_data "`outstub'/census_block_master.dta", log(`logfile') ///
        key(block) replace
    export delimited "`outstub'/census_block_master.csv", replace
end

program clean_tract_usps_zip_xwalk
    syntax, instub(str)
    
    import excel "`instub'/TRACT_ZIP_032010.xlsx", ///
        firstrow clear
    keep TRACT ZIP RES_RATIO
    rename (TRACT ZIP RES_RATIO) ///
	    (tract zipcode_hud res_ratio) 
		   
    gen neg_res_ratio = -res_ratio
    bysort tract (neg_res_ratio): keep if _n == 1
    drop neg_res_ratio res_ratio
	
	gen statefips = substr(tract, 1, 2) 
	gen countyfips = substr(tract, 1, 5) 
end

program clean_centroids
    syntax, instub(str)
	
    use "`instub'/census_blocks_2010_centroids_coord.dta", clear
    rename _ID     cb_centroid_geo_id
    rename (_X _Y) (longitude latitude)
    
    merge m:1 cb_centroid_geo_id using "`instub'/census_blocks_2010_centroids_db.dta", ///
        keep(1 3) nogen
    rename (cnss_bl      nm_hs10     cnt_wn_) ///
           (block num_house10 centroid_own_poly)
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

main
