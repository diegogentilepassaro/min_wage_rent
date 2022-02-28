remove(list = ls())

library(sf)
library(dplyr)
library(spData)
library(tmap)
library(tmaptools)
library(leaflet)
library(ggplot2)

main <- function(){
  in_map  <- "../../../drive/raw_data/shapefiles/USPS_zipcodes"
  in_geo  <- "../../../base/geo_master/output"
  in_data <- "../../../drive/derived_large/shares"
  
  df_data <- prepare_data(in_map, in_geo, in_data)
  
  events <- list(list("chicago",   16980, 2018),
                 #list("san_diego", 41740, 2018),
                 #list("seattle",   42660, 2018),
                 list("nyc",       35620, 2018),
                 #list("kc",        28140, 2018),
                 list("bay_area",  41860, 2018))
                 # Name CBSA10, Code CBSA10, start date, end date
  
  lapply(events,
    function(event) {
      df <- prepare_event_data(df_data, event[[2]], event[[3]])
      
      
      for (tt in c("", "_lowinc", "_young")) {
        
        resid_var   <- paste0("share", tt ,"_residents_ofCBSA")
        workers_var <- paste0("share", tt ,"_workers_ofCBSA")
        
        lab <- ""
        if (tt == "_lowinc") lab <- " low-income"
        if (tt == "_young")  lab <- " young"
        
        max_break <- round(max(c(df[[resid_var]], df[[workers_var]]), 
                               na.rm = TRUE), digits = 2)
        
        build_map(df, resid_var, 
                  paste0("Share", lab, "\nresidents (%)"), 
                  c(0, max_break/2, max_break), 
                  paste0(event[[1]], event[[3]], "_share_residents", tt))
        build_map(df, workers_var, 
                  paste0("Share", lab, "\nworkers (%)"), 
                  c(0, max_break/2, max_break), 
                  paste0(event[[1]], event[[3]], "_share_workers", tt))
      }
    }
  ) -> l
}

prepare_data <- function(in_map, in_geo, in_data) {
  
  df_map <- read_sf(dsn = in_map, 
                    layer = "USPS_zipcodes_July2020") %>%
    select(ZIP_CODE) %>%
    rename(zipcode = ZIP_CODE)
  
  shares <- data.table::fread(file.path(in_data, "zipcode_shares.csv"),
                              colClasses = c(zipcode ="character", 
                                             year ="integer")) %>%
    select(zipcode, year,
           residents, residents_young, residents_lowinc,
           workers,   workers_young,   workers_lowinc,
           share_residents_young,      share_residents_lowinc,
           share_workers_young,        share_workers_lowinc)
  
  geo_master <- data.table::fread(file.path(in_geo, "zip_county_place_usps_master.csv"),
                                  select     = c("zipcode", "cbsa10"),
                                  colClasses = c(zipcode ="character", 
                                                 cbsa10 = "character"))
  
  df_map %>%
    left_join(shares, by = "zipcode") %>%
    left_join(geo_master, by = "zipcode")
}

prepare_event_data <- function(data, cbsa10_code, year_num){
  data %>%
    filter(cbsa10 == cbsa10_code,
           year   == year_num) %>%
    mutate(share_residents_ofCBSA        = 100*residents       /sum(residents),
           share_lowinc_residents_ofCBSA = 100*residents_lowinc/sum(residents_lowinc),
           share_young_residents_ofCBSA  = 100*residents_young /sum(residents_young),
           share_workers_ofCBSA          = 100*workers         /sum(workers),
           share_lowinc_workers_ofCBSA   = 100*workers_lowinc  /sum(workers_lowinc),
           share_young_workers_ofCBSA    = 100*workers_young   /sum(workers_young)) %>%
    ungroup() %>%
    replace(is.na(.), 0)
}

build_map <- function(data, var, var_legend, break_values,
                      map_name, .dpi = 250){
  
  map <- tm_shape(data) + 
    tm_fill(col = var,
            title = var_legend,
            style = "cont",
            palette = c("#A6E1F4", "#077187"),
            breaks = break_values,
            textNA = "NA") +
    tm_borders(col = "white", lwd = .01, alpha = 0.7) +
    tm_layout(legend.position = c("left", "bottom"),
    	      frame = FALSE)
  
  tmap_save(map, 
            paste0("../output/", map_name, ".png"),
            dpi = .dpi)
  tmap_save(map, 
            paste0("../output/", map_name, ".eps"))
}

main()
