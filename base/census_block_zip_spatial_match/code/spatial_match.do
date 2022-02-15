clear all
set more off
adopath + ../../../lib/stata/min_wage/ado

program main
    local instub_xwalk    "../../../drive/raw_data/zcta_census_tract/"
    local instub          "../temp"
	local outstub         "../../../drive/base_large/census_block_zip_spatial_match"
    local logfile         "../output/data_file_manifest.log"
	
	clean_zcta_tract_xwalk, instub(`instub_xwalk')
	save_data "`instub'/tract_to_zcta.dta", ///
	    key(statefips countyfips census_tract) replace 
		
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
	drop longitude latitude usps_zip_poly_geo_id cb_centroid_geo_id
	merge m:1 statefips countyfips census_tract using "`instub'/tract_to_zcta.dta", ///
	    keep(1 3) nogen
	save_data "`outstub'/census_block_master.dta", ///
	    key(census_block) log(`logfile') replace
end

program clean_zcta_tract_xwalk
    syntax, instub(str)
	
	import delimited "`instub'/zcta_census_tract.txt", ///
	    clear stringcols(1 2 3 4 5)

	gen   neg_hupt = -hupt	
	bysort state county tract (neg_hupt): keep if _n == 1
	drop neg_hupt
	
	keep state county zcta5 tract
	rename (state county zcta5 tract) ///
	    (statefips countyfips zcta census_tract)
end

main
