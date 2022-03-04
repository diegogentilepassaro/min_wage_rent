remove(list = ls())

library(data.table)
library(zoo)
library(stringr)
source("../../../lib/R/save_data.R")

setDTthreads(20)

main <- function(){
  in_master  <- "../../../drive/base_large/tract_master"
  in_mw_data <- "../../../base/min_wage/output"
  in_acs     <- "../../../drive/base_large/demographics"
  outstub    <- "../temp"
  log_file   <- "../output/data_file_manifest.log"
  
  if (file.exists(log_file)) file.remove(log_file)
  
  yy <- 2011
  mm <- 1

  dt_geo <- load_geographies(in_master)
  
  dt_acs <- fread(file.path(in_acs, "acs_tract_2011.csv"),
                  select = list(character = c("tract"),
                                numeric = c("population", "n_hhlds",
                                            "med_hhld_inc", "n_workers", "n_workers_less_10k_inc",
                                            "n_workers_10to15k_inc", "n_workers_15to25k_inc",
                                            "n_workers_25to35k_inc", "n_workers_35to50k_inc",
                                            "n_workers_50to65k_inc", "n_workers_65to75k_inc",
                                            "n_workers_more_75k_inc")))
  
  dt_mw  <- load_mw(in_mw_data)
  
  dt <- copy(dt_geo)
  dt[, c("year", "month") := .(yy, mm)]

  dt <- assemble_statutory_mw(dt, dt_mw)
  dt <- dt[, c("tract", "place_code", "countyfips", 
               "cbsa", "statefips", 
               "fed_mw", "state_mw", "statutory_mw")]
  
  dt <- merge(dt, dt_acs, all.x = TRUE)
  
  fwrite(dt, file.path(outstub, "tract_income_at_baseline.csv"))
}

load_geographies <- function(instub) {
  dt <- fread(file.path(instub, "tract_master.csv"),
              select = list(character = c("tract", "place_code", "place_name", 
                                          "countyfips", "countyfips_name",
                                          "cbsa", "statefips")))
  
  dt <- manual_corrections(dt)
  
  return(dt)
}

manual_corrections <- function(dt) {
  
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
  
  state_mw[, event := 1*(state_mw != shift(state_mw)), by = .(statefips)]
  
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
  setnames(county_mw, old = c("locality",    mw_vars), 
                      new = c("countyfips_name", county_mw_vars))
  
  local_mw <- local_mw[iscounty == 0, ][, iscounty := NULL]
  setnames(local_mw, old = c("locality",   mw_vars),
                     new = c("place_name", local_mw_vars))
  
  county_mw <- county_mw[, .(countyfips_name, statefips, county_mw, year, month)]
  local_mw <- local_mw[,   .(place_name,  statefips, local_mw,  year, month)]
  
  county_mw[, event := 1*(county_mw != shift(county_mw)), by = .(countyfips_name, statefips)]
  local_mw[,  event := 1*(local_mw  != shift(local_mw)),  by = .(place_name,  statefips)]
  
  return(list("state"  = state_mw, 
              "county" = county_mw, 
              "local"  = local_mw))
}


assemble_statutory_mw <- function(dt, dt_mw) {
  
  dt <- dt_mw$state[dt,  on = c("statefips",                    "year", "month")][, event := NULL]
  dt <- dt_mw$county[dt, on = c("statefips", "countyfips_name", "year", "month")][, event := NULL]
  dt <- dt_mw$local[dt,  on = c("statefips", "place_name",      "year", "month")][, event := NULL]
  
  # Compute statutory MW
  dt[, statutory_mw := pmax(local_mw, county_mw, state_mw, fed_mw, na.rm = T)]
  
  return(dt)
}

main()
