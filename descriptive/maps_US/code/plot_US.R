remove(list = ls())

library(sf)
library(dplyr)
library(tmap)
library(tmaptools)
library(leaflet)
library(ggplot2)
library(data.table)

main <- function(){
  in_map_states  <- "../../../drive/raw_data/shapefiles/states"
  in_map <- "../../../drive/raw_data/shapefiles/USPS_zipcodes"
  in_zip <- "../../../drive/derived_large/zipcode"
  dpi <- 600
  
  data_states <- read_sf(dsn = in_map_states, layer = "state") %>%
    select(STPOSTAL) %>%
    rename(state_name = STPOSTAL) %>%
    filter(!(state_name %in% c("AK", "HI", "VI", "MP", "PR", "GU", "AS")))
  data_states <- data_states[st_is_valid(data_states),]
  
  df_all <- prepare_data(in_map, in_zip)

  pop_density_map <- tm_shape(data_states) +
    tm_polygons(lwd = 0.5) +
    tm_shape(df_all) + 
    tm_fill(col   = "pop2010_per_sq_miles",
            title = "Population\ndensity (pop per sq mile)",
            style = "quantile",
            n     = 5,
            palette = c("white", "#fff0f0", "#ffd6d6", "#ff9494", "#ff0000"),
            alpha = 0.8) +
    tmap_mode("plot") + 
    tmap_options(check.and.fix = TRUE) +
    tm_layout(frame = FALSE)
  
  tmap_save(pop_density_map,
            "../output/USPS_zipcodes_pop_density.png",
            dpi = dpi)

  zillow_zipcodes_map <- tm_shape(data_states) +
    tm_polygons(lwd = 0.5) +
    tm_shape(df_all) + 
    tm_fill(col   = "in_zillow",
            title = "Has Zillow\nrents data",
            style ="cat", 
            palette = c("white", "red"),
            alpha = 0.8) +
    tmap_mode("plot") + 
    tmap_options(check.and.fix = TRUE) +
    tm_layout(frame = FALSE)

  tmap_save(zillow_zipcodes_map, 
            "../output/USPS_zipcodes_zillow_data.png",
            dpi = dpi)
}

prepare_data <- function(in_map, in_zip) {
  map <- read_sf(dsn = in_map, 
                           layer = "USPS_zipcodes_July2020") %>%
    select(ZIP_CODE, PO_NAME, STATE, SQMI) %>%
    rename(zipcode = ZIP_CODE, zipcode_name = PO_NAME,
           state_name = STATE, area_sq_miles = SQMI) %>%
    filter(is.na(area_sq_miles) == FALSE) 
  
  zips <- data.table::fread(file.path(in_zip, "zipcode_cross.csv"),
                            select = list(character = c("zipcode" , 
                                                        "statefips"),
                                          numeric   = c("population_cens2010", 
                                                        "n_months_zillow_rents")))

  data_for_map <- left_join(map, zips, by = "zipcode") %>%
    filter(is.na(area_sq_miles) == FALSE) %>%
    filter(area_sq_miles != 0) %>%
    mutate(in_zillow = case_when(n_months_zillow_rents > 0 ~ 1,
                                 TRUE ~ 0),
           pop2010_per_sq_miles = case_when(is.na(population_cens2010/area_sq_miles) == TRUE ~ 0,
                                            TRUE ~ population_cens2010/area_sq_miles)) %>%
    filter(!(state_name %in% c("AK", "HI", "VI", "MP", "PR", "GU", "AS")))
  data_for_map <- data_for_map[st_is_valid(data_for_map),]
  
  return(data_for_map)
}

main()
