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
  in_data <- "../output"
  
  df_all <- prepare_data(in_map, in_data)
  
  events <- list(list("chicago",   16980, 2019, 7),
                 list("san_diego", 41740, 2019, 1),
                 list("seattle",   42660, 2019, 1),
                 list("nyc",       35620, 2019, 1),
                 list("kc",        28140, 2019, 1),
                 list("bay_area",  41860, 2019, 1))
                 # Name CBSA10, Code CBSA10, change date
    # "d_ln_rents", 
  rent_vars <- c("hat_d_ln_rents_resMWonly", "hatfe_d_ln_rents_resMWonly",
                 "hat_d_ln_rents_baseline", "hatfe_d_ln_rents_baseline")
  resid_vars <- c("resid_resMWonly", "resid_baseline", "resid_wkpl_on_res_MW")
  
  for (event in events) {
    
    df <- df_all %>%
      filter(cbsa10 == event[[2]], year == event[[3]], month == event[[4]])
    
    df <- st_sf(df)
    df <- df %>% filter(!st_is_empty(.))
    
    min_rent <- round(min(unlist(lapply(rent_vars, function(x) min(df[[x]], na.rm = T)))), digits = 3)
    max_rent <- round(max(unlist(lapply(rent_vars, function(x) max(df[[x]], na.rm = T)))), digits = 3)
    
    for (var in rent_vars) {
      breaks   <- c(min_rent, round((min_rent + max_rent)/2, digits = 3), max_rent)
      filename <- paste0(event[[1]], "_", event[[3]], "-", event[[4]], "_", var)
      
      build_map(df, var, get_ylab(var), breaks, filename)
    }
    
    min_resid <- round(min(unlist(lapply(resid_vars, function(x) min(df[[x]], na.rm = T)))), digits = 3)
    max_resid <- round(max(unlist(lapply(resid_vars, function(x) max(df[[x]], na.rm = T)))), digits = 3)
    
    for (var in resid_vars) {
      breaks   <- c(min_resid, round((min_resid + max_resid)/2, digits = 3), max_resid)
      filename <- paste0(event[[1]], "_", event[[3]], "-", event[[4]], "_", var)
      
      build_map(df, var, "Change in\nresidual", breaks, filename)
    }
  }
}

prepare_data <- function(in_map, in_data) {
  
  USPS_zipcodes <- read_sf(dsn = in_map, 
                           layer = "USPS_zipcodes_July2020") %>%
    select(ZIP_CODE) %>% rename(zipcode = ZIP_CODE)
  
  pred_data <- data.table::fread(file.path(in_data, "predictions.csv"),
                                 colClasses = c(zipcode ="character", cbsa10 = "character"))
  
  resid_vars <- names(pred_data)[grepl("resid", names(pred_data))]
  rent_vars  <- names(pred_data)[grepl("rents",   names(pred_data))]
  
  pred_data <- pred_data %>%
    select_at(c("zipcode", "cbsa10", "year", "month", "d_ln_rents", 
                "d_ln_mw", "d_exp_ln_mw_17", resid_vars, rent_vars))
  
  left_join(USPS_zipcodes, pred_data, by = "zipcode")
}

get_ylab <- function(var) {
  if (var == "d_ln_rents") return("Change in\nlog rents")
  if (var %in% c("hat_d_ln_rents_resMWonly", "hatfe_d_ln_rents_resMWonly",
                 "hat_d_ln_rents_baseline", "hatfe_d_ln_rents_baseline")) {
    return("Pred. Chg. in\nlog rents")
  }
}

build_map <- function(df, var, var_legend, break_values,
                      map_name, .dpi = 250){
  
  map <- tm_shape(df) + 
    tm_fill(col = var,
            title = var_legend,
            style = "cont",
            palette = c("#A6E1F4", "#077187"),
            breaks = break_values,
            textNA = "NA") +
    tm_borders(col = "white", lwd = .01, alpha = 0.7) +
    tm_layout(legend.position = c("left", "bottom"))
  
  tmap_save(map, 
            paste0("../output/", map_name, ".png"),
            dpi = .dpi)
}

main()
