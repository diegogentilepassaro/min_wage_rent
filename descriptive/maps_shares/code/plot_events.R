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
  in_counties   <- "../../../drive/raw_data/shapefiles/counties"
  in_geo  <- "../../../drive/base_large/zipcode_master"
  in_data <- "../../../drive/derived_large/od_shares"
  
  df_data <- prepare_data(in_map, in_geo, in_data)

  counties <- read_sf(dsn = in_counties, 
                      layer = "cb_2018_us_county_500k") %>%
    select(COUNTYFP) %>%
    rename(countyfp = COUNTYFP)
  
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
        
        resid_var   <- paste0("sh", tt ,"_residents_ofCBSA")
        workers_var <- paste0("sh", tt ,"_workers_ofCBSA")
        
        lab <- ""
        if (tt == "_lowinc") lab <- " low-income"
        if (tt == "_young")  lab <- " young"
        
        max_break <- round(max(c(df[[resid_var]], df[[workers_var]]), 
                               na.rm = TRUE), digits = 2)
        
        build_map(df, counties, resid_var, 
                  paste0("Share", lab, "\nresidents (%)"), 
                  c(0, max_break/2, max_break), 
                  paste0(event[[1]], event[[3]], "_share_residents", tt))
        build_map(df, counties, workers_var, 
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
  
  level_vars <- c("residents", "residents_young", "residents_lowinc",
                  "workers",   "workers_young",   "workers_lowinc")
  shares <- data.table::fread(file.path(in_data, "zipcode_shares.csv"),
                              colClasses = c(zipcode ="character", 
                                             year ="integer")) %>%
    select_at(c("zipcode", "year", level_vars,
               "sh_residents_young", "sh_residents_lowinc",
               "sh_workers_young",   "sh_workers_lowinc"))
  
  for (var in level_vars) {
    shares[is.na(get(var)), c(var) := 0]
  }
  
  geo_master <- data.table::fread(file.path(in_geo, "zipcode_master.csv"),
                                  select     = list(character = c("zipcode", "cbsa")))
  
  df_map %>%
    left_join(shares,     by = "zipcode") %>%
    left_join(geo_master, by = "zipcode")
}

prepare_event_data <- function(data, cbsa_code, year_num) {
  data %>%
    filter(cbsa == cbsa_code,
           year == year_num) %>%
    mutate(sh_residents_ofCBSA        = 100*residents       /sum(residents),
           sh_lowinc_residents_ofCBSA = 100*residents_lowinc/sum(residents_lowinc),
           sh_young_residents_ofCBSA  = 100*residents_young /sum(residents_young),
           sh_workers_ofCBSA          = 100*workers         /sum(workers),
           sh_lowinc_workers_ofCBSA   = 100*workers_lowinc  /sum(workers_lowinc),
           sh_young_workers_ofCBSA    = 100*workers_young   /sum(workers_young)) %>%
    ungroup() %>%
    replace(is.na(.), 0)
}

build_map <- function(data, counties, var, var_legend, break_values,
                      map_name, .dpi = 300) {
  
  map <- tm_shape(data) + 
    tm_fill(col = var,
            title = var_legend,
            style = "cont",
            palette = c("#A6E1F4", "#077187"),
            breaks = break_values,
            textNA = "NA") +
    tm_borders(col = "white", lwd = .008, alpha = 1) +
    tm_layout(legend.position = c("left", "bottom"),
              legend.bg.color = "white",
              frame = FALSE) +
    tm_shape(counties) +
    tm_borders(col = "black", lwd = 0.008,
               alpha = 1) +
    tmap_options(check.and.fix = TRUE)
  
  tmap_save(map, 
            paste0("../output/", map_name, "_png.png"),
            dpi = .dpi)
  tmap_save(map, 
            paste0("../output/", map_name, ".eps"))
}

main()
