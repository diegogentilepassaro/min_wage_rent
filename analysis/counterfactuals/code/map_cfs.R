remove(list = ls())

library(sf)
library(dplyr)
library(spData)
library(tmap)
library(tmaptools)
library(ggplot2)

main <- function() {
  in_map   <- "../../../drive/raw_data/shapefiles/USPS_zipcodes"
  in_counties   <- "../../../drive/raw_data/shapefiles/counties"
  in_large <- "../../../drive/analysis_large/counterfactuals"

  USPS_zipcodes <- read_sf(dsn   = in_map, 
                           layer = "USPS_zipcodes_July2020") %>%
    select(ZIP_CODE, PO_NAME, STATE, POPULATION, SQMI, POP_SQMI) %>%
    rename(zipcode = ZIP_CODE, zipcode_name = PO_NAME,
           state_name = STATE)

  counties <- read_sf(dsn   = in_counties, 
                      layer = "cb_2018_us_county_500k") %>%
    select(COUNTYFP) %>%
    rename(countyfp = COUNTYFP)
  
  df_cf_data <- data.table::fread(file.path(in_large, "data_counterfactuals.csv"),
                                  colClasses = c(zipcode = "character")) %>%
    filter(year == 2020)
  
  # Housing expenditure  
  df_all <- df_cf_data %>%
    filter(counterfactual == "fed_9usd")

  df_all <- left_join(USPS_zipcodes, df_all, by = "zipcode")

  df_chicago <- df_all %>% filter(cbsa == 16980)

  min_break <- round(min(df_chicago$s_imputed, na.rm = TRUE), digits = 3)
  max_break <- round(max(df_chicago$s_imputed, na.rm = TRUE), digits = 3)
  
  build_map(data         = df_chicago, 
            counties     = counties,
            var          = "s_imputed", 
            var_legend   ="Share of expenditure in housing", 
            break_values = c(min_break, (min_break + max_break)/2, max_break), 
            map_name     = "chicago_s_imputed")

  # Maps for each counterfactual
  
  plotsdata_list <- list(
    c("d_mw_res",           "Change in\nresidence MW",           "chicago_d_mw_res",      "d_mw_res"),
    c("d_mw_wkp",           "Change in\nworkplace MW",           "chicago_d_mw_wkp",      "d_mw_res"),
    c("change_ln_rents",    "Change in log rents\nper sq. foot", "chicago_d_ln_rents",    "change_ln_rents"),
    c("change_ln_wagebill", "Change in\nlog total wages",        "chicago_d_ln_wagebill", "change_ln_wagebill"),
    c("rho_with_imputed",   "Share pocketed\nby landlords",      "chicago_rho_with_imputed", "rho_with_imputed"))
      # Var                 # Legend                             # Plot name              # Break var
  
  for (cf in c("fed_9usd", "chi14")) {
    
    df_all <- left_join(USPS_zipcodes, 
                        df_cf_data %>% filter(counterfactual == cf), 
                        by = "zipcode")
    df_chicago <- df_all %>% filter(cbsa == 16980)

    lapply(plotsdata_list, 
      function(plt_data) {

        yvar        <- plt_data[1]
        legend_name <- plt_data[2]
        plot_name   <- paste0(plt_data[3], "_", cf)
        break_var   <- plt_data[4]

        min_break <- round(min(df_chicago[[break_var]], na.rm = TRUE), digits = 3)
        max_break <- round(max(df_chicago[[break_var]], na.rm = TRUE), digits = 3)

        if ("mw" %in% yvar) {
          break_vals <- c(0, max_break/2, max_break)
        } 
        else {
          if (grepl("rents|wage", yvar)) {
            min_break <- round(min(min(df_chicago$change_ln_wagebill, na.rm = T),
                                   min(df_chicago$change_ln_rents, na.rm = T)), 
                                digits = 3)
            max_break <- round(max(max(df_chicago$change_ln_wagebill, na.rm = T),
                                   max(df_chicago$change_ln_rents, na.rm = T)), 
                                digits = 3)
          }
          break_vals <- c(min_break, (min_break + max_break)/2, max_break)
        }
        
        build_map(data         = df_chicago, 
                  counties     = counties,
                  var          = yvar, 
                  var_legend   = legend_name, 
                  break_values = break_vals, 
                  map_name     = plot_name)
    })
  }
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
    tm_borders(col = "white", lwd = .006, alpha = 1) +
    tm_layout(legend.position = c("left", "bottom"),
              legend.bg.color = "white",
              frame = FALSE) +
    tm_shape(counties) +
    tm_borders(col = "black", lwd = .002,
               alpha = 1) +
    tmap_options(check.and.fix = TRUE)
  
  tmap_save(map, 
            paste0("../output/", map_name, "_png.png"),
            dpi = .dpi)
  tmap_save(map, 
            paste0("../output/", map_name, ".eps"))
}

main()
