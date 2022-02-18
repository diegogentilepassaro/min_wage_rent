remove(list = ls())

library(data.table)
library(zoo)
library(stringr)
source("../../../lib/R/save_data.R")

setDTthreads(20)

main <- function(){
  in_master   <- "../../../drive/base_large/census_block_master"
  in_counties <- "../../../drive/raw_data/census_population/orig"
  in_mw_data  <- "../../../base/min_wage/output"
  outstub     <- "../../../drive/derived_large/min_wage"
  log_file    <- "../output/data_file_manifest.log"
  
  if (file.exists(log_file)) file.remove(log_file)
  
  start_date <- "2009-07-01"
  end_date   <- "2020-01-31"
  
  dt_geo <- load_geographies(in_master, in_counties)
  dt_mw  <- load_mw(in_mw_data)
  
  ## MW Panels
  mw_panel_zip  <- data.table()
  mw_panel_cnty <- data.table()
  for (yy in 2009:2020) {
    
    month_range <- c(1, 12)
    if (yy == 2009) month_range <- c(7, 12)
    if (yy == 2020) month_range <- c(1, 7)
    
    dt <- build_frame(copy(dt_geo), month_range)
    dt[, year := yy]
    
    dt <- assemble_statutory_mw(dt, dt_mw)
    
    mw_panel_zip  <- rbindlist(
     list(mw_panel_zip,
          collapse_data(copy(dt), key_vars = c("zipcode",   "year", "month")))
    )
    mw_panel_cnty <- rbindlist(
     list(mw_panel_zip,
          collapse_data(copy(dt), key_vars = c("countyfips", "year", "month")))
    )
  }
  rm(dt, dt_geo, dt_mw)
   
   
  save_data(mw_panel_zip,   key = c("zipcode", "year", "month"),
           filename = file.path(outstub, "zip_statutory_mw.csv"),
           logfile  = log_file)
  save_data(mw_panel_zip,  key = c("zipcode", "year", "month"),
           filename = file.path(outstub, "zip_statutory_mw.dta"),
           nolog    = TRUE)
  
  save_data(mw_panel_cnty,  key = c("countyfips", "year", "month"),
            filename = file.path(outstub, "county_statutory_mw.csv"),
            logfile  = log_file)
  save_data(mw_panel_cnty,  key = c("countyfips", "year", "month"),
            filename = file.path(outstub, "county_statutory_mw.dta"),
            nolog    = TRUE)
  
  
  ## MW Counterfactuals
  dt_cf <- compute_counterfactual(mw_panel_zip)
  
  save_data(dt_cf, key = c("zipcode", "year", "month"),
            filename = file.path(outstub, "zipcode_cfs.csv"),
            logfile  = log_file)
  save_data(dt_cf, key = c("zipcode", "year", "month"),
           filename = file.path(outstub, "zipcode_cfs.dta"),
           nolog    = TRUE)
}

load_geographies <- function(in_master, in_counties) {
  
  dt_cnty <- fread(file.path(in_counties, "co-est2020.csv"), 
                   colClasses = "character",
                   select = c("STATE", "COUNTY", "CTYNAME"))
  setnames(dt_cnty, c("statefips", "countyfips", "county_name"))
  
  dt_cnty <- dt_cnty[countyfips != "000"]
  dt_cnty[, countyfips := paste0(statefips, countyfips)][, statefips := NULL]
  
  dt_cnty[, county_name := gsub("\\s*\\w*$", " County", county_name)]
  
  dt <- fread(file.path(in_master, "census_block_master.csv"),
              select = list(character = c("statefips",  "countyfips", "census_block",
                                          "place_code", "place_name", "zipcode"), 
                            numeric   = "num_house10"))
  
  dt <- dt[zipcode != ""]  # 0.366 % of census blocks do not have a zip code
  
  dt <- dt[dt_cnty, on = "countyfips"]
  
  dt <- manual_corrections(dt)
  
  return(dt)
}

manual_corrections <- function(dt) {
  
  dt[place_name == "Louisville/Jefferson County metro government (balance)", 
     place_name := "Lousville"]
  dt[place_name == "New York",  place_name := "New York City"]
  dt[place_name == "St. Paul",  place_name := "Saint Paul"]
  
  # Test whether other fixes are necessary
  
  return(dt)
}


load_mw <- function(instub) {
  
  # State MW
  state_mw <- fread(file.path(instub, "state_monthly.csv"))
  
  setnames(state_mw, old = "mw", new = "state_mw")
  
  state_mw[, c("year", "month") := .(as.numeric(substr(monthly_date, 1, 4)),
                                     as.numeric(gsub("m", "", substr(monthly_date, 5, length(monthly_date)))))]
  state_mw[, c("monthly_date", "statename") := NULL]
  
  state_mw[, statefips := str_pad(as.character(statefips), 2, pad = 0)]
  state_mw[, stateabb  := NULL]
  
  # Substate MW
  local_mw <- fread(file.path(instub, "substate_monthly.csv"))
  
  local_mw[, c("year", "month") := .(as.numeric(substr(monthly_date, 1, 4)),
                                     as.numeric(gsub("m", "", substr(monthly_date, 5, length(monthly_date)))))]
  local_mw[, c("monthly_date", "statename") := NULL]
  
  local_mw[, statefips := str_pad(as.character(statefips), 2, pad = 0)]
  local_mw[, iscounty  := 1*grepl("County", locality)]
  
  mw_vars        <- names(local_mw)[grepl("mw", names(local_mw))]
  county_mw_vars <- paste0("county_", mw_vars)
  local_mw_vars  <- paste0("local_",  mw_vars)
  
  county_mw <- local_mw[iscounty == 1, ][, iscounty := NULL]
  setnames(county_mw, old = c("locality", mw_vars), 
           new = c("county_name",   county_mw_vars))
  
  local_mw <- local_mw[iscounty == 0, ][, iscounty := NULL]
  setnames(local_mw, old = c("locality",  mw_vars),
           new = c("place_name", local_mw_vars))
  
  county_mw <- county_mw[, .(county_name, statefips, county_mw, year, month)]
  local_mw <- local_mw[,   .(place_name,  statefips, local_mw,  year, month)]
  
  return(list("state"  = state_mw, 
              "county" = county_mw, 
              "local"  = local_mw))
}


build_frame <- function(dt_geo, month_range) {
  
  dt <- data.table()
  for (mm in seq(month_range[[1]], month_range[[2]])) {
    
    dt <- rbindlist(list(dt,
                         copy(dt_geo)[, month := mm]))
  }
  
  return(dt)
}


assemble_statutory_mw <- function(dt, dt_mw) {
   
   dt <- dt_mw$state[dt,  on = c("statefips",                "year", "month")]
   dt <- dt_mw$county[dt, on = c("statefips", "county_name", "year", "month")]
   dt <- dt_mw$local[dt,  on = c("statefips", "place_name",  "year", "month")]
   
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
   
   dt[, binding_fed_mw := 1*(statutory_mw == fed_mw)]
   
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
                sh_houses_w_fed_mw       = weighted.mean(binding_fed_mw,           num_house10)),
            by = key_vars]
   
   return(dt)
}

compute_counterfactual <- function(dt) {

  dt_cf <- dt[  (year == 2019 & month == 12)
              | (year == 2020 & month == 01)]

  dt_cf[, fed_mw_cf_10pc  := fed_mw*1.1]
  dt_cf[, fed_mw_cf_9usd  := 9]
  dt_cf[, fed_mw_cf_15usd := 15]
  
  dt_cf[, statutory_mw_cf_10pc := statutory_mw]
  dt_cf[year == 2020 & month ==  1, statutory_mw_cf_10pc := fcase(
    binding_mw == 1, fed_mw_cf_10pc,
    sh_houses_w_fed_mw*fed_mw_cf_10pc + (1-sh_houses_w_fed_mw)*statutory_mw, fed_mw_cf_10pc
  )]
  
  dt_cf[, statutory_mw_cf_9usd := statutory_mw]
  dt_cf[year == 2020 & month ==  1, statutory_mw_cf_9usd := fcase(
    binding_mw == 1, fed_mw_cf_10pc,
    sh_houses_w_fed_mw*fed_mw_cf_9usd + (1-sh_houses_w_fed_mw)*statutory_mw, fed_mw_cf_9usd
  )]
  
  dt_cf[, statutory_mw_cf_15usd := statutory_mw]
  dt_cf[year == 2020 & month ==  1, statutory_mw_cf_15usd := fcase(
    binding_mw == 1, fed_mw_cf_10pc,
    sh_houses_w_fed_mw*fed_mw_cf_9usd + (1-sh_houses_w_fed_mw)*statutory_mw, fed_mw_cf_9usd
  )]
  
  return(dt_cf)
}


main()
