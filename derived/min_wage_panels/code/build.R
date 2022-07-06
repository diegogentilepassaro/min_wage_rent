remove(list = ls())
library(data.table)
library(zoo)
library(stringr)

source("../../../lib/R/save_data.R")
source("../../../lib/R/load_mw.R")

setDTthreads(18)

main <- function(){
  in_master   <- "../../../drive/base_large/census_block_master"
  in_mw_data  <- "../../../base/min_wage/output"
  outstub     <- "../../../drive/derived_large/min_wage_panels"
  log_file    <- "../output/data_file_manifest.log"
  
  if (file.exists(log_file)) file.remove(log_file)
  
  start_ym <- c(2010, 1)
  end_ym   <- c(2020, 12)
  cf_ym    <- c(2019, 12)  
  
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
         | (yy == start_ym[1] & mm %in% c(1, start_ym[2]))      #  or it's the first month of the year
         | (yy == end_ym[1]   & mm == end_ym[2]))          {    #  or it's the last year-month of panel
                                                                #  then compute MW levels
        
        dt <- copy(dt_geo)
        
        dt[, c("year", "month") := .(yy, mm)]
        
        print(sprintf("Computing MW for year %s and month %s", yy, mm))
        
        dt <- assemble_statutory_mw(dt, dt_mw)
        
        if (yy == cf_ym[1] & mm == cf_ym[2]) {                # Save block level data for cfs
          dt_blocklevel_for_cf <- copy(dt)
        }
        
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
  rm(dt, dt_geo, dt_mw, 
     dt_year_zip, dt_year_zip_prev, dt_year_cnty, dt_year_cnty_prev)

  ## Save data
  keep_vars <- names(mw_panel_zip)[!grepl("sh_|cbsa", names(mw_panel_zip))]   
  save_data(mw_panel_zip[, ..keep_vars],   
            key      = c("zipcode", "year", "month"),
            filename = file.path(outstub, "zip_statutory_mw.dta"),
            logfile  = log_file)
  fwrite(mw_panel_zip[, ..keep_vars],
         file = file.path(outstub, "zip_statutory_mw.csv"))
  
  keep_vars <- names(mw_panel_cnty)[!grepl("sh_|cbsa", names(mw_panel_cnty))]  
  save_data(mw_panel_cnty[, ..keep_vars],  
            key      = c("countyfips", "year", "month"),
            filename = file.path(outstub, "county_statutory_mw.dta"),
            logfile  = log_file)
  fwrite(mw_panel_cnty[, ..keep_vars],  
         file = file.path(outstub, "county_statutory_mw.csv"))
  
  ## MW Counterfactuals
  dt_cf <- compute_counterfactual(dt_blocklevel_for_cf)
  rm(dt_blocklevel_for_cf)
  
  save_data(dt_cf, key = c("zipcode", "year", "month"),
            filename = file.path(outstub, "zipcode_cfs.dta"),
            logfile  = log_file)
  fwrite(dt_cf, 
         file = file.path(outstub, "zipcode_cfs.csv"))
}

load_geographies <- function(instub) {
  
  dt <- fread(file.path(instub, "census_block_master.csv"),
              select = list(character = c("statefips", "countyfips", "county_name", 
                                          "block", "place_code", "place_name", 
                                          "zipcode", "cbsa"), 
                            numeric   = "num_house10"))
  
  # Drop small % of census blocks do not have a zip code
  # Thus, we will compute simple mean of statutory MW
  dt <- dt[zipcode != ""]
    
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
  
  ## Assign federal MW to zipcodes under 00199
  dt[as.numeric(zipcode) <= 199, fed_mw    := 7.25]
  dt[as.numeric(zipcode) <= 199, state_mw  := NA_real_]
  dt[as.numeric(zipcode) <= 199, county_mw := NA_real_]
  
  # Compute statutory MW
  dt[, statutory_mw             := pmax(local_mw, county_mw, state_mw, fed_mw, na.rm = T)]
  dt[, statutory_mw_ignorelocal := pmax(state_mw, fed_mw, na.rm = T)]
  
  # Compute binding MW
  dt[, binding_mw := fcase(
    pmax(local_mw, county_mw, state_mw, fed_mw, na.rm = T) == fed_mw,    1,  # Fed MW
    pmax(local_mw, county_mw, state_mw, fed_mw, na.rm = T) == state_mw,  2,  # State MW
    pmax(local_mw, county_mw, state_mw, fed_mw, na.rm = T) == county_mw, 3,  # County MW
    pmax(local_mw, county_mw, state_mw, fed_mw, na.rm = T) == local_mw,  4,  # City MW
    default = NA
  )]
  dt[, binding_mw_ignorelocal := fcase(
    pmax(state_mw, fed_mw, na.rm = T) == fed_mw,    1,  # Fed MW
    pmax(state_mw, fed_mw, na.rm = T) == state_mw,  2,  # State MW
    default = NA
  )]
  
  return(dt)
}


collapse_data <- function(dt, key_vars = c("zipcode", "year", "month")) {
  
  # Impute num_house10 = 1 for locations that have no housing, eg, university zip codes
  if ("zipcode" %in% key_vars) {
    dt[, sum_houses_geo := sum(num_house10), by = .(zipcode)]
  } else {
    dt[, sum_houses_geo := sum(num_house10), by = .(countyfips)]
  }
  dt[sum_houses_geo == 0, num_house10 := 1]
  dt[, sum_houses_geo := NULL]

  dt <- dt[, .(statutory_mw             = weighted.mean(statutory_mw,             num_house10),
               statutory_mw_ignorelocal = weighted.mean(statutory_mw_ignorelocal, num_house10),
               local_mw                 = weighted.mean(local_mw,                 num_house10),
               county_mw                = weighted.mean(county_mw,                num_house10),
               state_mw                 = weighted.mean(state_mw,                 num_house10),
               fed_mw                   = weighted.mean(fed_mw,                   num_house10),
               binding_mw               = weighted.mean(binding_mw,               num_house10),
               binding_mw_ignorelocal   = weighted.mean(binding_mw_ignorelocal,   num_house10),
               binding_mw_max           = max(binding_mw)                                     ,
               binding_mw_min           = min(binding_mw)                                     ),
          keyby = key_vars]
   
  return(dt)
}


compute_counterfactual <- function(dt) {

  dt <- dt[, .(block, zipcode, cbsa, countyfips, place_code, num_house10,
               fed_mw, state_mw, county_mw, local_mw, statutory_mw)]
  
  dt_cf_2019 <- copy(dt)
  dt_cf_2020 <- copy(dt)
  dt_cf_2019[, c("year", "month") := .(2019, 12)]
  dt_cf_2020[, c("year", "month") := .(2020, 1 )]
  
  dt <- rbindlist(list(dt_cf_2019, dt_cf_2020))
  rm(dt_cf_2019, dt_cf_2020)
  
  dt[, fed_mw_cf_10pc     := fifelse(year == 2019, fed_mw, fed_mw*1.1)]
  dt[, fed_mw_cf_9usd     := fifelse(year == 2019, fed_mw, 9)]
  dt[, fed_mw_cf_15usd    := fifelse(year == 2019, fed_mw, 15)]
  
  for (stub in c("_10pc", "_9usd", "_15usd")) {
    cf_mw_var <- paste0("fed_mw_cf", stub)
    new_var   <- paste0("statutory_mw_cf", stub)

    dt[, c(new_var) := pmax(local_mw, county_mw, state_mw, get(cf_mw_var), na.rm = T)]
  }
  
  dt[, local_mw_cf_chi14     := fifelse(year == 2019 & place_code == "1714000", local_mw, local_mw + 1)]
  dt[, statutory_mw_cf_chi14 := pmax(local_mw_cf_chi14, county_mw, state_mw, fed_mw, na.rm = T)]
  
  dt <- dt[, .(statutory_mw_cf_10pc  = weighted.mean(statutory_mw_cf_10pc,  num_house10),
               statutory_mw_cf_9usd  = weighted.mean(statutory_mw_cf_9usd,  num_house10),
               statutory_mw_cf_15usd = weighted.mean(statutory_mw_cf_15usd, num_house10),
               statutory_mw_cf_chi14 = weighted.mean(statutory_mw_cf_chi14, num_house10),
               fed_mw_cf_10pc        = weighted.mean(fed_mw_cf_10pc,        num_house10),
               fed_mw_cf_9usd        = weighted.mean(fed_mw_cf_9usd,        num_house10),
               fed_mw_cf_15usd       = weighted.mean(fed_mw_cf_15usd,       num_house10),
               local_mw              = weighted.mean(local_mw,              num_house10),
               local_mw_cf_chi14     = weighted.mean(local_mw_cf_chi14,     num_house10),
               county_mw             = weighted.mean(county_mw,             num_house10),
               state_mw              = weighted.mean(state_mw,              num_house10)),
           by = .(zipcode, year, month)]
  
  dt[, c("cbsa", "countyfips") := NULL]
  
  return(dt)
}


main()
