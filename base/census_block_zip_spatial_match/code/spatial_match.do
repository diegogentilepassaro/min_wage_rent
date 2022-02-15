clear all
set more off
adopath + ../../../lib/stata/min_wage/ado

program main
    local instub_xwalk    "../../../drive/raw_data/zcta_census_tract/"
    local instub          "../temp"
	local outstub         "../../../../drive/base_large/census_block_zip_spatial_match"
    local logfile         "../output/data_file_manifest.log"
    
    use "`instub'/census_blocks_2010_centroids_coord.dta", clear
	rename _ID cb_centroid_geo_id
	rename (_X _Y) (longitude latitude)
	geoinpoly latitude longitude ///
		using "`instub'/USPS_zipcodes_July2020_coord.dta"
		
	rename _ID usps_zip_poly_geo_id
	merge m:1 cb_centroid_geo_id using "`instub'/census_blocks_2010_centroids_db.dta", ///
		keep(1 3) nogen
    rename (statfps cntyfps cnss_tr cnss_bl nm_hs10 pop10) ///
	    (statefips countyfips census_tract census_block num_house10 pop10)
	merge m:1 usps_zip_poly_geo_id using "`instub'/USPS_zipcodes_July2020_db.dta", ///
		keep(1 3) nogen	keepusing(ZIP_CODE)
	rename ZIP_CODE zipcode
	
	save_data "`outstub'/census_to_zip.dta", ///
	    key(census_block) log(`logfile') replace
end

main
