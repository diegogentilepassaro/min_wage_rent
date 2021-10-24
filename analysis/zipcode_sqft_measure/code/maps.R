remove(list = ls())

library(sf)
library(dplyr)
library(spData)
library(tmap)
library(tmaptools)
library(leaflet)
library(ggplot2)
library(data.table)

main <- function(){
  in_map  <- "../../../drive/raw_data/shapefiles/USPS_zipcodes"
  in_acs  <- "../../../base/acs_rental_occupation/output"

  USPS_zipcodes <- read_sf(dsn = in_map, 
                           layer = "USPS_zipcodes_July2020") %>%
    select(ZIP_CODE, STATE) %>%
    rename(zipcode = ZIP_CODE, state_abb = STATE) %>%
    filter(state_abb != "AK" & state_abb != "HI" & state_abb != "VI" & state_abb != "MP"
           & state_abb != "PR" & state_abb != "GU" & state_abb != "AS")
  USPS_zipcodes <- USPS_zipcodes[st_is_valid(USPS_zipcodes),]
  
  sqft_dt <- fread("../output/sqft_data_with_predictions.csv",
                     colClasses = c(zipcode = "character", zcta = "character"))
  
  acs_rental_occup_dt <- fread(file.path(in_acs, "acs_rental_occupation.csv"),
                               colClasses = c(zcta = "character"))
  
  dt <- left_join(USPS_zipcodes, sqft_dt, by = "zipcode")
  dt <- left_join(dt, acs_rental_occup_dt, by = "zcta")
  dt <- dt %>%
    mutate(total_rented_space = p_sqft_from_rents*renter_occupied)

  build_map(dt, "sqft_from_rents", "sqft of median rental post", 
            "sqft_from_rents")
  build_map(dt, "p_sqft_from_rents", "Predicted sqft of median rental post", 
            "p_sqft_from_rents") 
  build_map(dt, "total_rented_space", "Total rented space", 
            "tot_rented_space") 
}

build_map <- function(data, var, var_legend, map_name,
                      .dpi = 300){
  map <- tm_shape(data) + 
    tm_fill(col = var,
            title = var_legend,
            style = "cont",
            palette = c("#A6E1F4", "#077187"),
            textNA = "NA") +
    tm_borders(col = "white", lwd = .01, alpha = 0.7) +
    tm_layout(legend.position = c("left", "bottom"))
  
  tmap_save(map, 
            paste0("../output/", map_name, ".png"),
            dpi = .dpi)
  tmap_save(map, 
            paste0("../output/", map_name, ".eps"))
}

main()
