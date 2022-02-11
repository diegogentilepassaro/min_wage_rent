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
  in_data <- "../../../drive/derived_large/estimation_samples"
  
  df_all <- prepare_data(in_map, in_data)
  
  events <- list(list("chicago",   16980, 2019, 6, 2019, 12),
                 list("san_diego", 41740, 2018, 12, 2019, 6),
                 list("seattle",   42660, 2018, 12, 2019, 6),
                 list("nyc",       35620, 2018, 12, 2019, 6),
                 list("kc",        28140, 2018, 12, 2019, 6),
                 list("bay_area",  41860, 2018, 12, 2019, 6))
                 # Name CBSA10, Code CBSA10, start date, end date
  
  lapply(events,
    function(event) {
      df <- restrict_and_build_changes(df_all, event[[2]],
                                       event[[3]], event[[4]], event[[5]], event[[6]]) 
      max_break_mw    <- round(max(df$change_ln_actual_mw, na.rm = TRUE), digits = 2)
      max_break_rents <- round(max(df$change_ln_rents, na.rm = TRUE), digits = 2)
      
      build_map(df, "change_ln_actual_mw", "Change in\nresidence MW", 
                c(0, max_break_mw/2, max_break_mw), 
                paste0(event[[1]], "_", event[[3]], "-", event[[4]], "_actual_mw"))
      build_map(df, "change_exp_ln_mw", "Change in\nworkplace MW", 
                c(0, max_break_mw/2, max_break_mw), 
                paste0(event[[1]], event[[3]], "-", event[[4]], "_exp_mw"))
      build_map(df, "change_ln_rents", "Change in\nlog(rents)",
                c(0, max_break_rents/2, max_break_rents),
                paste0(event[[1]], event[[3]], "-", event[[4]], "_rents"))
    }
  ) -> l
}

prepare_data <- function(in_map, in_data) {
  
  USPS_zipcodes <- read_sf(dsn = in_map, 
                           layer = "USPS_zipcodes_July2020") %>%
    select(ZIP_CODE, PO_NAME, STATE, POPULATION, SQMI, POP_SQMI) %>%
    rename(zipcode = ZIP_CODE, zipcode_name = PO_NAME,
           state_name = STATE, pop2020 = POPULATION, 
           area_sq_miles = SQMI, pop2020_per_sq_miles = POP_SQMI)
  
  mw_rent_data <- data.table::fread(file.path(in_data, "all_zipcode_months.csv"),
                                    colClasses = c(zipcode ="character", place_code ="character", 
                                                   countyfips = "character", cbsa10 = "character",
                                                   zcta ="character", place_name = "character", 
                                                   county_name = "character", cbsa10_name = "character",
                                                   state_abb = "character", statefips = "character")) %>%
    select(zipcode, cbsa10, year, month, actual_mw, exp_ln_mw_17, medrentpricepsqft_SFCC) %>%
    mutate(ln_actual_mw = log(actual_mw),
           ln_rent_var  = log(medrentpricepsqft_SFCC))
  
  left_join(USPS_zipcodes, mw_rent_data, by = "zipcode")
}

restrict_and_build_changes <- function(data, cbsa10_code, year_lb, month_lb, 
                                       year_ub, month_ub){
  data %>%
    filter(cbsa10 == cbsa10_code) %>%
    filter(  (year == year_lb & month == month_lb) 
           | (year == year_ub & month == month_ub)) %>%
    group_by(zipcode) %>%
    summarise(change_actual_mw    = last(actual_mw)   - first(actual_mw), 
              change_ln_actual_mw = last(ln_actual_mw) - first(ln_actual_mw),
              change_exp_ln_mw    = last(exp_ln_mw_17)   - first(exp_ln_mw_17),
              change_ln_rents     = last(ln_rent_var) - first(ln_rent_var)) %>%
    ungroup()
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
