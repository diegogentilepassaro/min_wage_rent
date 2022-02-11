remove(list = ls())

library(sf)
library(dplyr)
library(spData)
library(tmap)
library(tmaptools)
library(leaflet)
library(ggplot2)

main <- function(){
  in_map_states  <- "../../../drive/raw_data/shapefiles/states"
  in_map_zip  <- "../../../drive/raw_data/shapefiles/USPS_zipcodes"
  in_data <- "../../../drive/derived_large/estimation_samples"
  
  data_for_map <- prepare_data(in_map_zip, in_data)
  
  data_states <- read_sf(dsn = in_map_states, layer = "state") %>%
    select(STPOSTAL) %>%
    rename(state_name = STPOSTAL) %>%
    filter(!(state_name %in% c("AK", "HI", "VI", "MP", "PR", "GU", "AS")))
  data_states <- data_states[st_is_valid(data_states),]
  
  build_map(data_for_map, data_states,  "change_perc_actual_mw", "Percentage change in binding MW", 
            paste0("US", "change_perc_actual_mw"))
}

prepare_data <- function(in_map_zip, in_data) {
  USPS_zipcodes <- read_sf(dsn = in_map_zip, 
                           layer = "USPS_zipcodes_July2020") %>%
    select(ZIP_CODE, PO_NAME, STATE, POPULATION, SQMI, POP_SQMI) %>%
    rename(zipcode = ZIP_CODE, zipcode_name = PO_NAME,
           state_name = STATE, pop2020 = POPULATION, 
           area_sq_miles = SQMI, pop2020_per_sq_miles = POP_SQMI)

  mw_rent_data <- data.table::fread(file.path(in_data, "all_zipcode_months.csv"),
                                    colClasses = c(zipcode ="character",
                                                   state_abb = "character", statefips = "character")) %>%
    select(zipcode, state_abb, year, month, actual_mw) %>%
    mutate(ln_actual_mw = log(actual_mw)) %>%
    filter((year == 2010 & month == 1) | (year == 2019 & month == 12)) %>%
    group_by(zipcode) %>%
    summarise(change_perc_actual_mw = 100*(last(actual_mw) - first(actual_mw))/first(actual_mw)) %>%
    ungroup()
  
  data_for_map <- left_join(USPS_zipcodes, mw_rent_data, by = "zipcode") %>%
    filter(is.na(area_sq_miles) == FALSE)  %>%
    filter(state_name != "AK" & state_name != "HI" & state_name != "VI" & state_name != "MP"
           & state_name != "PR" & state_name != "GU" & state_name != "AS")
  data_for_map <- data_for_map[st_is_valid(data_for_map),]

  return(data_for_map)
}

build_map <- function(data_zip, data_states, var, var_legend, map_name,
                      .dpi = 600){
  map <- tm_shape(data_states) +
    tm_polygons(lwd = 0.5) +
    tm_shape(data_zip) +
    tm_fill(col = var,
            title = var_legend,
            style = "cont",
            palette = c("#FFFFFF", "#A6E1F4", "#077187"),
            textNA = "NA",
            alpha = 0.8) +
    tm_layout(legend.position = c("left", "bottom")) +
    tmap_options(check.and.fix = TRUE) +
    tm_layout(frame = FALSE)

  tmap_save(map, 
            paste0("../output/", map_name, ".png"),
            dpi = .dpi)
}

main()
