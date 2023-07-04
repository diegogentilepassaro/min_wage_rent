remove(list = ls())

library(sf)
library(dplyr)
library(spData)
library(tmap)
library(tmaptools)
library(leaflet)
library(ggplot2)

main <- function(){
  in_map   <- "../../../drive/raw_data/shapefiles/USPS_zipcodes"
  in_counties   <- "../../../drive/raw_data/shapefiles/counties"
  in_states   <- "../../../drive/raw_data/shapefiles/states"
  in_resid <- "../../fd_baseline/output"
  in_data  <- "../../../drive/derived_large/zipcode_month"
  
  data_for_map <- prepare_data(in_map, in_data, in_resid)
  
  counties <- read_sf(dsn = in_counties, 
                      layer = "cb_2018_us_county_500k") %>%
    select(COUNTYFP) %>%
    rename(countyfp = COUNTYFP)
  
  states <- read_sf(dsn = in_states, 
                      layer = "state") %>%
    select(STFIPS) %>%
    rename(stfips = STFIPS)
  
  events <- list(list("chicago",   16980, 2019, 6,  2019, 7),
                 list("san_diego", 41740, 2018, 12, 2019, 1),
                 #list("seattle",   42660, 2018, 12, 2019, 1),
                 list("nyc",       35620, 2018, 12, 2019, 1),
                 list("kc",        28140, 2018, 12, 2019, 1),
                 list("bay_area",  41860, 2018, 12, 2019, 1))
                 # Name cbsa, Code cbsa, start date, end date
  
  lapply(events,
    function(event) {
      df <- restrict_and_build_changes(data_for_map, event[[2]],
                                       event[[3]], event[[4]], event[[5]], event[[6]]) 
      max_break_mw      <- round(max(df$change_ln_statutory_mw, na.rm = TRUE), digits = 2)
      max_break_rents   <- round(max(df$change_ln_rents, na.rm = TRUE), digits = 2)
      max_break_r_rents <- round(max(df$change_resid_ln_rents, na.rm = TRUE), digits = 2)
      max_break_r_wkp   <- round(max(df$change_resid_wkp_on_res, na.rm = TRUE), digits = 2)
      
      build_map(df, counties, states, 
                "change_ln_statutory_mw", "Change in\nresidence MW", 
                c(0, max_break_mw/2, max_break_mw), 
                paste0(event[[1]], "_", event[[3]], "-", event[[4]], "_statutory_mw"))
      build_map(df, counties, states, 
                "change_wkp_ln_mw", "Change in\nworkplace MW", 
                c(0, max_break_mw/2, max_break_mw), 
                paste0(event[[1]], event[[3]], "-", event[[4]], "_wkp_mw"))
      build_map(df, counties, states, 
                "change_ln_rents", "Change in\nlog rents",
                c(0, max_break_rents/2, max_break_rents),
                paste0(event[[1]], event[[3]], "-", event[[4]], "_rents"))
      build_map(df, counties, states, 
                "change_resid_ln_rents", "Residualized change\nin log rents",
                c(0, max_break_r_rents/2, max_break_r_rents),
                paste0(event[[1]], event[[3]], "-", event[[4]], "_r_rents"))
      build_map(df, counties, states, 
                "change_resid_wkp_on_res", "Residualized change\nin workplace MW ",
                c(0, max_break_r_wkp/2, max_break_r_wkp),
                paste0(event[[1]], event[[3]], "-", event[[4]], "_r_wkp"))
    }
  ) -> l
}

prepare_data <- function(in_map, in_data, in_resid) {
  
  USPS_zipcodes <- read_sf(dsn = in_map, 
                           layer = "USPS_zipcodes_July2020") %>%
    select(ZIP_CODE, PO_NAME, STATE, POPULATION, SQMI, POP_SQMI) %>%
    rename(zipcode = ZIP_CODE, zipcode_name = PO_NAME,
           state_name = STATE, pop2020 = POPULATION, 
           area_sq_miles = SQMI, pop2020_per_sq_miles = POP_SQMI)
  
  mw_rent_data <- data.table::fread(file.path(in_data, "zipcode_month_panel.csv"),
                                    colClasses = c(zipcode ="character", 
                                                   cbsa = "character", statefips = "character")) %>%
    select(zipcode, cbsa, year, month, statutory_mw, 
           mw_wkp_tot_17, medrentpricepsqft_SFCC) %>%
    mutate(ln_statutory_mw = log(statutory_mw),
           ln_rent_var  = log(medrentpricepsqft_SFCC))
  resid_data <- data.table::fread(file.path(in_resid, "estimates_unbal_residuals.csv"),
                                  colClasses = c(zipcode ="character"))
  mw_rent_data <- left_join(mw_rent_data, resid_data, by = c("zipcode", "year", "month"))

  data_for_map <- left_join(USPS_zipcodes, mw_rent_data, by = "zipcode")
  
  return(data_for_map)
}

restrict_and_build_changes <- function(data, cbsa_code, year_lb, month_lb, 
                                       year_ub, month_ub){
  data %>%
    filter(cbsa == cbsa_code) %>%
    filter(  (year == year_lb & month == month_lb) 
           | (year == year_ub & month == month_ub)) %>%
    group_by(zipcode) %>%
    summarise(change_statutory_mw      = last(statutory_mw)   - first(statutory_mw), 
              change_ln_statutory_mw   = last(ln_statutory_mw) - first(ln_statutory_mw),
              change_wkp_ln_mw         = last(mw_wkp_tot_17)   - first(mw_wkp_tot_17),
              change_ln_rents          = last(ln_rent_var) - first(ln_rent_var),
              change_resid_ln_rents    = last(r_unbal_static_both),
              change_resid_wkp_on_res  = last(r_unbal_mw_wkp_on_res_mw)) %>%
    ungroup()
}

build_map <- function(data, counties, states, var, var_legend, break_values,
                      map_name, .dpi = 300){
  
  map <- tm_shape(data) + 
    tm_fill(col = var,
            title = var_legend,
            style = "cont",
            palette = c("#A6E1F4", "#077187"),
            breaks = break_values,
            textNA = "NA") +
    tm_borders(col = "white", lwd = .008, alpha = 0.9) +
    tm_layout(legend.position = c("left", "bottom"),
    	      frame = FALSE) +
    tm_shape(counties) +
    tm_borders(col = "black", lwd = 0.008,
               alpha = 0.5) +
    tm_shape(states) +
    tm_borders(col = "blue", lwd = 0.05,
               alpha = 1) +
    tmap_options(check.and.fix = TRUE)
  
  tmap_save(map, 
            paste0("../output/", map_name, ".png"),
            dpi = .dpi)
  tmap_save(map, 
            paste0("../output/", map_name, ".eps"))
}

main()
