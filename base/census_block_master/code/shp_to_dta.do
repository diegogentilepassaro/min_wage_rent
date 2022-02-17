clear all
set more off

program main
    local in_centroids "../../../drive/base_large/census_blocks_centroids"
    local in_usps_zip  "../../../drive/raw_data/shapefiles/USPS_zipcodes"
    local in_places    "../../../drive/base_large/assemble_place_shapefile"
    local outstub      "../temp"
        
    shp2dta using "`in_usps_zip'/USPS_zipcodes_July2020.shp",        ///
        database("`outstub'/USPS_zipcodes_July2020_db")              ///
        coordinates("`outstub'/USPS_zipcodes_July2020_coord")        ///
        genid(usps_zip_poly_geo_id) replace
		
    shp2dta using "`in_places'/us_places_2010.shp",        ///
        database("`outstub'/us_places_2010_db")              ///
        coordinates("`outstub'/us_places_2010_coord")        ///
        genid(us_place_poly_geo_id) replace
		
    shp2dta using "`in_centroids'/census_blocks_2010_centroids.shp", ///
        database("`outstub'/census_blocks_2010_centroids_db")        ///
        coordinates("`outstub'/census_blocks_2010_centroids_coord")  ///
        genid(cb_centroid_geo_id) replace
end


main
