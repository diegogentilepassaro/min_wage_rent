remove(list = ls())

library(data.table)
library(sf)
library(dplyr)
library(spData)
library(tmap)
library(tmaptools)
library(ggplot2)

main <- function() {
  in_map  <- "../../../drive/raw_data/shapefiles/USPS_zipcodes"
  in_data <- "../output/"

  USPS_zipcodes <- read_sf(dsn = in_map, 
                           layer = "USPS_zipcodes_July2020") %>%
    select(ZIP_CODE, PO_NAME, STATE, POPULATION, SQMI, POP_SQMI) %>%
    rename(zipcode = ZIP_CODE, zipcode_name = PO_NAME,
           state_name = STATE)
  
  # fed_9usd counterfactual
  
  df_all <- fread(file.path(in_data, "data_counterfactuals.csv"),
                  colClasses = c(zipcode = "character")) %>%
    filter(counterfactual == "fed_9usd",
           year           == 2020)

  df_all <- left_join(USPS_zipcodes, df_all, by = "zipcode")

  df_chicago <- df_all %>% filter(cbsa == 16980)

  max_break_mw <- round(max(df_chicago$d_mw_res, na.rm = TRUE), digits = 2)
  
  build_map(data = df_chicago, 
            var = "d_mw_res", 
            var_legend ="Change in\nresidence MW", 
            break_values = c(0, max_break_mw/2, max_break_mw), 
            map_name = "chicago_d_mw_res")
  
  build_map(data = df_chicago, 
            var = "d_mw_wkp", 
            var_legend ="Change in\nworkplace MW", 
            break_values = c(0, max_break_mw/2, max_break_mw), 
            map_name = "chicago_d_mw_wkp")
  
  min_break_rents <- round(min(df_chicago$change_ln_rents, na.rm = TRUE), digits = 2)
  max_break_rents <- round(max(df_chicago$change_ln_rents, na.rm = TRUE), digits = 2)
  
  build_map(data = df_chicago, 
            var = "change_ln_rents", 
            var_legend ="Change in log rents\nper sq. foot", 
            break_values = c(min_break_rents, (min_break_rents + max_break_rents)/2, max_break_rents), 
            map_name = "chicago_d_ln_rents")

  min_break_wagebill <- round(min(df_chicago$change_ln_wagebill, na.rm = TRUE), digits = 2)
  max_break_wagebill <- round(max(df_chicago$change_ln_wagebill, na.rm = TRUE), digits = 2)
  
  build_map(data = df_chicago, 
            var = "change_ln_wagebill", 
            var_legend ="Change in\nlog total wages", 
            break_values = c(min_break_wagebill, (min_break_wagebill + max_break_wagebill)/2, max_break_wagebill), 
            map_name = "chicago_d_ln_wagebill")

  df <- df_chicago %>% 
    filter(is.na(s_imputed) == FALSE)
  min_break_s_imputed <- round(min(df$s_imputed, na.rm = TRUE), digits = 3)
  max_break_s_imputed <- round(max(df$s_imputed, na.rm = TRUE), digits = 3)
  
  build_map(data = df, 
            var = "s_imputed", 
            var_legend ="Share of expenditure in housing", 
            break_values = c(min_break_s_imputed, (min_break_s_imputed + max_break_s_imputed)/2, max_break_s_imputed), 
            map_name = "chicago_s_imputed")

  min_break_rho_with_imputed <- round(min(df_chicago$rho_with_imputed, na.rm = TRUE), digits = 3)
  max_break_rho_with_imputed <- round(max(df_chicago$rho_with_imputed, na.rm = TRUE), digits = 3)
  
  build_map(data = df_chicago, 
            var = "rho_with_imputed", 
            var_legend ="Share pocketed\nby landlords", 
            break_values = c(min_break_rho_with_imputed, (min_break_rho_with_imputed + max_break_rho_with_imputed)/2, max_break_rho_with_imputed), 
            map_name = "chicago_rho_with_imputed")
  
  # chi14 counterfactual
  
  df_all <- fread(file.path(in_data, "data_counterfactuals.csv"),
                  colClasses = c(zipcode = "character")) %>%
    filter(counterfactual == "chi14",
           year           == 2020)
  
  df_all <- left_join(USPS_zipcodes, df_all, by = "zipcode")
  
  df_chicago <- df_all %>% filter(cbsa == 16980)
  
  max_break_mw <- round(max(df_chicago$d_mw_res, na.rm = TRUE), digits = 4)
  
  build_map(data = df_chicago, 
            var = "d_mw_res", 
            var_legend ="Change in\nresidence MW", 
            break_values = c(0, max_break_mw/2, max_break_mw), 
            map_name = "chicago_d_mw_res_chi14")
  
  build_map(data = df_chicago, 
            var = "d_mw_wkp", 
            var_legend ="Change in\nworkplace MW", 
            break_values = c(0, max_break_mw/2, max_break_mw), 
            map_name = "chicago_d_mw_wkp_chi14")
  
  min_break_rents <- round(min(df_chicago$change_ln_rents, na.rm = TRUE), digits = 5)
  max_break_rents <- round(max(df_chicago$change_ln_rents, na.rm = TRUE), digits = 5)
  
  build_map(data = df_chicago, 
            var = "change_ln_rents", 
            var_legend ="Change in log rents\nper sq. foot", 
            break_values = c(min_break_rents, (min_break_rents + max_break_rents)/2, max_break_rents), 
            map_name = "chicago_d_ln_rents_chi14")
  
  min_break_wagebill <- round(min(df_chicago$change_ln_wagebill, na.rm = TRUE), digits = 4)
  max_break_wagebill <- round(max(df_chicago$change_ln_wagebill, na.rm = TRUE), digits = 4)
  
  build_map(data = df_chicago, 
            var = "change_ln_wagebill", 
            var_legend ="Change in\nlog total wages", 
            break_values = c(min_break_wagebill, (min_break_wagebill + max_break_wagebill)/2, max_break_wagebill), 
            map_name = "chicago_d_ln_wagebill_chi14")
  
  df <- df_chicago %>% 
    filter(is.na(s_imputed) == FALSE)
  min_break_s_imputed <- round(min(df$s_imputed, na.rm = TRUE), digits = 5)
  max_break_s_imputed <- round(max(df$s_imputed, na.rm = TRUE), digits = 5)
  
  build_map(data = df, 
            var = "s_imputed", 
            var_legend ="Share of expenditure in housing", 
            break_values = c(min_break_s_imputed, (min_break_s_imputed + max_break_s_imputed)/2, max_break_s_imputed), 
            map_name = "chicago_s_imputed_chi14")
  
  min_break_rho_with_imputed <- round(min(df_chicago$rho_with_imputed, na.rm = TRUE), digits = 6)
  max_break_rho_with_imputed <- round(max(df_chicago$rho_with_imputed, na.rm = TRUE), digits = 6)
  
  build_map(data = df_chicago, 
            var = "rho_with_imputed", 
            var_legend ="Share pocketed\nby landlords", 
            break_values = c(min_break_rho_with_imputed, (min_break_rho_with_imputed + max_break_rho_with_imputed)/2, max_break_rho_with_imputed), 
            map_name = "chicago_rho_with_imputed_chi14")
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
