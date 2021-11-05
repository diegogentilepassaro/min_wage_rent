remove(list = ls())

library(data.table)
library(sf)
library(dplyr)
library(spData)
library(tmap)
library(tmaptools)
library(leaflet)
library(ggplot2)

main <- function(){
  in_map  <- "../../../drive/raw_data/shapefiles/USPS_zipcodes"
  in_data <- "../output/"
  
  USPS_zipcodes <- read_sf(dsn = in_map, 
                           layer = "USPS_zipcodes_July2020") %>%
    select(ZIP_CODE, PO_NAME, STATE, POPULATION, SQMI, POP_SQMI) %>%
    rename(zipcode = ZIP_CODE, zipcode_name = PO_NAME,
           state_name = STATE, pop2020 = POPULATION, 
           area_sq_miles = SQMI, pop2020_per_sq_miles = POP_SQMI)
  
  df_all <- fread(file.path(in_data, "predicted_changes_in_rents.csv"),
                  colClasses = c(zipcode = "character"))
  df_all <- left_join(USPS_zipcodes, df_all, by = "zipcode")
  df_chicago <- df_all %>%
    filter(cbsa10 == 16980)

  max_break_mw    <- round(max(df_chicago$d_ln_mw, na.rm = TRUE), digits = 2)
  
  build_map(data = df_chicago, 
            var = "d_ln_mw", 
            var_legend ="Counterfactual change \nin residence MW", 
            break_values = c(0, max_break_mw/2, max_break_mw), 
            map_name = "chicago_d_ln_mw")
  
  build_map(data = df_chicago, 
            var = "d_exp_ln_mw_17", 
            var_legend ="Counterfactual change \nin workplace MW", 
            break_values = c(0, max_break_mw/2, max_break_mw), 
            map_name = "chicago_d_exp_ln_mw")
  
  min_break_rents    <- round(min(df_chicago$change_ln_rents, na.rm = TRUE), digits = 2)
  max_break_rents    <- round(max(df_chicago$change_ln_rents, na.rm = TRUE), digits = 2)
  
  build_map(data = df_chicago, 
            var = "change_ln_rents", 
            var_legend ="Counterfactual change \nin log rents", 
            break_values = c(min_break_rents, max_break_rents/2, max_break_rents), 
            map_name = "chicago_d_ln_rents")
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
    tm_layout(legend.position = c("left", "bottom"))
  
  tmap_save(map, 
            paste0("../output/", map_name, ".png"),
            dpi = .dpi)
  tmap_save(map, 
            paste0("../output/", map_name, ".eps"))
}

main()
