remove(list = ls())

library(data.table)
library(zoo)
library(stringr)
source("../../../lib/R/save_data.R")
source("../../../lib/R/load_mw.R")

setDTthreads(20)

main <- function(){
  in_master   <- "../../../drive/base_large/census_block_master"
  in_mw_data  <- "../../../base/min_wage/output"
  outstub     <- "../../../drive/derived_large/min_wage_panels"
  log_file    <- "../output/data_file_manifest.log"
  
  if (file.exists(log_file)) file.remove(log_file)
  
  start_ym <- c(2009, 7)
  end_ym   <- c(2020, 1)
  
  dt_geo <- load_geographies(in_master)
  dt_mw  <- load_mw(in_mw_data)
  
  ## MW Panels
  mw_panel_zip  <- data.table()
  mw_panel_cnty <- data.table()
  for (yy in start_ym[1]:end_ym[1]) {
    
    month_range <- seq(1, 12)
    if (yy == start_ym[1]) month_range <- seq(start_ym[2], 12)
    if (yy == end_ym[1])   month_range <- seq(1,    end_ym[2])
    
    mm_mw_changes <- get_months_with_changes(dt_mw, yy)
    
    dt_year_zip  <- data.table()
    dt_year_cnty <- data.table()
    for (mm in month_range){
      
      if ( (mm %in% mm_mw_changes)                              # If there was a MW change
         | (yy == start_ym[1] & mm %in% c(1, start_ym[2]))) {   #  or the first month of the year
                                                                #  then compute MW levels
        
        dt <- copy(dt_geo)
        
        dt[, c("year", "month") := .(yy, mm)]
        
        dt <- assemble_statutory_mw(dt, dt_mw)
        
        dt_year_zip <- rbindlist(
          list(dt_year_zip, 
               collapse_data(copy(dt), key_vars = c("zipcode",   "year", "month"))))
        dt_year_cnty <- rbindlist(
          list(dt_year_cnty, 
               collapse_data(copy(dt), key_vars = c("countyfips", "year", "month"))))
      
      } else {                                           # If no MW change use previous month
        
        dt_year_zip_prev <- copy(dt_year_zip[year == yy & month == mm-1])
        dt_year_zip_prev[, month := mm]
        
        dt_year_zip <- rbindlist(list(dt_year_zip, dt_year_zip_prev))
        
        dt_year_cnty_prev <- copy(dt_year_cnty[year == yy & month == mm-1])
        dt_year_cnty_prev[, month := mm]
        
        dt_year_cnty <- rbindlist(list(dt_year_cnty, dt_year_cnty_prev))
      }
    }
    
    mw_panel_zip  <- rbindlist(list(mw_panel_zip,  dt_year_zip))
    mw_panel_cnty <- rbindlist(list(mw_panel_cnty, dt_year_cnty))
  }
  rm(dt, dt_geo, dt_mw)

  ## Assign federal MW to zipcodes under 00199 or places with missing statutory
  ##   Place with missing statutory correspond to states not available in base/min_wage
  mw_panel_zip[as.numeric(zipcode) <= 199 | is.na(statutory_mw), state_mw     := NA]
  mw_panel_zip[as.numeric(zipcode) <= 199 | is.na(statutory_mw), fed_mw       := 7.25]
  mw_panel_zip[as.numeric(zipcode) <= 199 | is.na(statutory_mw), statutory_mw := 7.25]

  keep_vars <- names(mw_panel_zip)[!grepl("sh_", names(mw_panel_zip))]   
  save_data(mw_panel_zip[, ..keep_vars],   
            key      = c("zipcode", "year", "month"),
            filename = file.path(outstub, "zip_statutory_mw.dta"),
            logfile  = log_file)
  fwrite(mw_panel_zip[, ..keep_vars],
         file = file.path(outstub, "zip_statutory_mw.csv"))
  
  keep_vars <- names(mw_panel_cnty)[!grepl("sh_", names(mw_panel_cnty))]  
  save_data(mw_panel_cnty[, ..keep_vars],  
            key      = c("countyfips", "year", "month"),
            filename = file.path(outstub, "county_statutory_mw.dta"),
            logfile  = log_file)
  fwrite(mw_panel_cnty[, ..keep_vars],  
         file = file.path(outstub, "county_statutory_mw.csv"))
  
  ## MW Counterfactuals
  dt_cf <- compute_counterfactual(mw_panel_zip)
  
  save_data(dt_cf, key = c("zipcode", "year", "month"),
            filename = file.path(outstub, "zipcode_cfs.csv"),
            logfile  = log_file)
  save_data(dt_cf, key = c("zipcode", "year", "month"),
           filename = file.path(outstub, "zipcode_cfs.dta"),
           nolog    = TRUE)
}

load_geographies <- function(instub) {
  
  dt <- fread(file.path(instub, "census_block_master.csv"),
              select = list(character = c("statefips",  "countyfips", 
                                          "county_name", "block",
                                          "place_code", "place_name", "zipcode"), 
                            numeric   = "num_house10"))
  
  dt <- dt[zipcode != ""]  # small % of census blocks do not have a zip code
    
  return(dt)
}

get_months_with_changes <- function(dt_mw, yy) {
  
  state_months  <- unique(dt_mw$state[year == yy  & event == 1]$month)
  county_months <- unique(dt_mw$county[year == yy & event == 1]$month)
  local_months  <- unique(dt_mw$local[year == yy  & event == 1]$month)
  
  return(unique(c(state_months,county_months,local_months)))
}


assemble_statutory_mw <- function(dt, dt_mw) {
  
  dt <- dt_mw$state[dt,  on = c("statefips",                "year", "month")][, event := NULL]
  dt <- dt_mw$county[dt, on = c("statefips", "county_name", "year", "month")][, event := NULL]
  dt <- dt_mw$local[dt,  on = c("statefips", "place_name",  "year", "month")][, event := NULL]
  
  # Compute statutory MW
  dt[, statutory_mw := pmax(local_mw, county_mw, state_mw, fed_mw, na.rm = T)]
  dt[, binding_mw := fcase(
    pmax(local_mw, county_mw, state_mw, fed_mw, na.rm = T) == fed_mw,    1,  # Fed MW
    pmax(local_mw, county_mw, state_mw, fed_mw, na.rm = T) == state_mw,  2,  # State MW
    pmax(local_mw, county_mw, state_mw, fed_mw, na.rm = T) == county_mw, 3,  # County MW
    pmax(local_mw, county_mw, state_mw, fed_mw, na.rm = T) == local_mw,  4,  # City MW
    default = NA
  )]
  
  dt[, statutory_mw_ignorelocal := pmax(state_mw, fed_mw, na.rm = T)]
  dt[, binding_mw_ignorelocal := fcase(
    pmax(state_mw, fed_mw, na.rm = T) == fed_mw,    1,  # Fed MW
    pmax(state_mw, fed_mw, na.rm = T) == state_mw,  2,  # State MW
    default = NA
  )]
  
  dt[, binding_mw_less_10pc  := 1*(statutory_mw <= 1.1*fed_mw)]
  dt[, binding_mw_less_9usd  := 1*(statutory_mw <  9)]
  dt[, binding_mw_less_15usd := 1*(statutory_mw <  15)]
  
  return(dt)
}


collapse_data <- function(dt, key_vars = c("zipcode", "year", "month")) {
   
   dt <- dt[, .(statutory_mw             = weighted.mean(statutory_mw,             num_house10),
                statutory_mw_ignorelocal = weighted.mean(statutory_mw_ignorelocal, num_house10),
                local_mw                 = weighted.mean(local_mw,                 num_house10),
                county_mw                = weighted.mean(county_mw,                num_house10),
                state_mw                 = weighted.mean(state_mw,                 num_house10),
                fed_mw                   = weighted.mean(fed_mw,                   num_house10),
                binding_mw               = weighted.mean(binding_mw,               num_house10),
                binding_mw_ignorelocal   = weighted.mean(binding_mw_ignorelocal,   num_house10),
                binding_mw_max           = max(binding_mw),
                binding_mw_min           = min(binding_mw),
                sh_houses_w_less_10pc    = weighted.mean(binding_mw_less_10pc,     num_house10),
                sh_houses_w_less_9usd    = weighted.mean(binding_mw_less_9usd,     num_house10),
                sh_houses_w_less_15usd   = weighted.mean(binding_mw_less_15usd,    num_house10)),
            keyby = key_vars]
   
   return(dt)
}

compute_counterfactual <- function(dt) {

  dt_cf <- dt[  (year == 2019 & month == 12)
              | (year == 2020 & month == 01)]

  dt_cf[, fed_mw_cf_10pc  := fed_mw*1.1]
  dt_cf[, fed_mw_cf_9usd  := 9]
  dt_cf[, fed_mw_cf_15usd := 15]
  
  for (stub in c("_10pc", "_9usd", "_15usd")) {
    cf_mw_var <- paste0("fed_mw_cf", stub)
    new_var   <- paste0("statutory_mw_cf", stub)
    share_var <- paste0("sh_houses_w_less", stub)

    dt_cf[, c(new_var) := statutory_mw]
    dt_cf[year == 2020 & month ==  1, 
      c(new_var) := get(share_var)*get(cf_mw_var) 
                  + (1 - get(share_var))*statutory_mw]
  }
  
  return(dt_cf)
}


main()
