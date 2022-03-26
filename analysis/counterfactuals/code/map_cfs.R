remove(list = ls())

library(data.table)
library(sf)
library(dplyr)
library(spData)
library(tmap)
library(tmaptools)
library(ggplot2)

main <- function(){
  in_map  <- "../../../drive/raw_data/shapefiles/USPS_zipcodes"
  in_data <- "../output/"

  USPS_zipcodes <- read_sf(dsn = in_map, 
                           layer = "USPS_zipcodes_July2020") %>%
    select(ZIP_CODE, PO_NAME, STATE, POPULATION, SQMI, POP_SQMI) %>%
    rename(zipcode = ZIP_CODE, zipcode_name = PO_NAME,
           state_name = STATE)
  
  df_all <- fread(file.path(in_data, "predicted_changes_in_rents.csv"),
                  colClasses = c(zipcode = "character"))
  df_all <- left_join(USPS_zipcodes, df_all, by = "zipcode")
  df_chicago <- df_all %>%
    filter(cbsa == 16980)

  max_break_mw <- round(max(df_chicago$d_mw_res, na.rm = TRUE), digits = 2)
  
  build_map(data = df_chicago, 
            var = "d_mw_res", 
            var_legend ="Counterfactual change\nin residence MW", 
            break_values = c(0, max_break_mw/2, max_break_mw), 
            map_name = "chicago_d_mw_res")
  
  build_map(data = df_chicago, 
            var = "d_mw_wkp_tot_17", 
            var_legend ="Counterfactual change\nin workplace MW", 
            break_values = c(0, max_break_mw/2, max_break_mw), 
            map_name = "chicago_d_mw_wkp_tot_17")
  
  min_break_rents <- round(min(df_chicago$change_ln_rents, na.rm = TRUE), digits = 2)
  max_break_rents <- round(max(df_chicago$change_ln_rents, na.rm = TRUE), digits = 2)
  
  build_map(data = df_chicago, 
            var = "change_ln_rents", 
            var_legend ="Counterfactual change \nin log rents", 
            break_values = c(min_break_rents, max_break_rents/2, max_break_rents), 
            map_name = "chicago_d_ln_rents")

  min_break_wagebill <- round(min(df_chicago$change_ln_wagebill, na.rm = TRUE), digits = 2)
  max_break_wagebill <- round(max(df_chicago$change_ln_wagebill, na.rm = TRUE), digits = 2)
  
  build_map(data = df_chicago, 
            var = "change_ln_wagebill", 
            var_legend ="Counterfactual change\nin log total wages", 
            break_values = c(min_break_wagebill, max_break_wagebill/2, max_break_wagebill), 
            map_name = "chicago_d_ln_wagebill")

  min_break_rho <- round(min(df_chicago$rho, na.rm = TRUE), digits = 2)
  max_break_rho <- round(max(df_chicago$rho, na.rm = TRUE), digits = 2)
  
  build_map(data = df_chicago, 
            var = "rho", 
            var_legend ="Landlord\nShare", 
            break_values = c(min_break_rho, max_break_rho/2, max_break_rho), 
            map_name = "chicago_rho")
}

build_map <- function(data, var, var_legend, break_values,
                      map_name, .dpi = 250) {
  
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
