remove(list = ls())

library(sf)
library(dplyr)
library(tmap)
library(tmaptools)
library(leaflet)
library(ggplot2)

main <- function(){
  in_map_states  <- "../../../drive/raw_data/shapefiles/states"
  in_map <- "../../../drive/raw_data/shapefiles/USPS_zipcodes"
  in_zip <- "../../../drive/derived_large/zipcode"

  data_states <- read_sf(dsn = in_map_states, layer = "state") %>%
    select(STPOSTAL) %>%
    rename(state_name = STPOSTAL) %>%
    filter(state_name != "AK" & state_name != "HI" & state_name != "VI" & state_name != "MP"
           & state_name != "PR" & state_name != "GU" & state_name != "AS")
  data_states <- data_states[st_is_valid(data_states),]
  
  df_all <- prepare_data(in_map, in_zip)

  #matched <- df_all %>%
  #  filter(!is.na(houses_zcta_place_county))
    
  pop_density_map <- tm_shape(data_states) +
    tm_polygons(lwd = 0.5) +
    tm_shape(df_all) + 
    tm_fill(col   = "pop2020_per_sq_miles",
            title = "Population\ndensity",
            style = "quantile",
            n     = 5,
            palette = c("white", "#fff0f0", "#ffd6d6", "#ff9494", "#ff0000"),
            alpha = 0.8) +
    tm_borders(lwd = .0001, alpha = 0.1) +
    tmap_mode("plot") + 
    tmap_options(check.and.fix = TRUE)

  tmap_save(pop_density_map,
            "../output/USPS_zipcodes_pop_density.eps")
  tmap_save(pop_density_map,
            "../output/USPS_zipcodes_pop_density.png",
            dpi = 600)
  
  zillow_zipcodes_map <- tm_shape(data_states) +
    tm_polygons(lwd = 0.5) +
    tm_shape(df_all) + 
    tm_fill(col   = "in_zillow",
            title = "Has Zillow\nrents data",
            style ="cat", 
            palette = c("white", "red"),
            alpha = 0.8) +
    tm_borders(lwd = .0001, alpha = 0.1) +
    tmap_mode("plot") + 
    tmap_options(check.and.fix = TRUE)

  tmap_save(zillow_zipcodes_map, 
            "../output/USPS_zipcodes_zillow_data.eps")
  tmap_save(zillow_zipcodes_map, 
            "../output/USPS_zipcodes_zillow_data.png",
            dpi = 600)
}


prepare_data <- function(in_map, in_zip) {
  
  map <- read_sf(dsn = in_map, 
                           layer = "USPS_zipcodes_July2020") %>%
    select(ZIP_CODE, PO_NAME, STATE, POPULATION, SQMI, POP_SQMI) %>%
    rename(zipcode = ZIP_CODE, zipcode_name = PO_NAME,
           state_name = STATE, pop2020 = POPULATION, 
           area_sq_miles = SQMI, pop2020_per_sq_miles = POP_SQMI)
  
  zips <- data.table::fread(file.path(in_zip, "zipcode_cross.csv"),
                            colClasses = c(zipcode ="character", place_code ="character", 
                                           countyfips = "character", cbsa10 = "character",
                                           zcta ="character", place_name = "character", 
                                           county_name = "character", cbsa10_name = "character",
                                           state_abb = "character", statefips = "character"))
  
  left_join(map, zips, by = "zipcode") %>%
    filter(is.na(area_sq_miles) == FALSE) %>%
    mutate(in_zillow = case_when(n_months_zillow_rents > 0 ~ 1,
                                 TRUE ~ 0)) %>%
    filter(state_abb != "AK" & state_abb != "HI")
}


main()
