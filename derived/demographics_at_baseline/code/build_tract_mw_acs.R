remove(list = ls())

library(data.table)
library(zoo)
library(stringr)
source("../../../lib/R/save_data.R")
source("../../../lib/R/load_mw.R")

setDTthreads(20)

main <- function(){
  in_master  <- "../../../drive/base_large/census_block_master"
  in_mw_data <- "../../../base/min_wage/output"
  in_acs     <- "../../../drive/base_large/demographics"
  outstub    <- "../temp"
  log_file   <- "../output/data_file_manifest.log"

  yy <- 2011
  mm <- 1

  dt_geo <- load_geographies(in_master)
  
  dt_mw  <- load_mw(in_mw_data)
  
  dt <- copy(dt_geo)
  dt[, c("year", "month") := .(yy, mm)]

  dt <- assemble_statutory_mw(dt, dt_mw)
  dt <- dt[, c("block", "tract", 
               "fed_mw", "state_mw", "county_mw", "local_mw", "statutory_mw",
               "num_house10")]
  dt <- collapse_data(dt, key_vars = c("tract"))

  dt_acs <- fread(file.path(in_acs, "acs_tract_2011.csv"),
                  select = list(character = c("tract"),
                                numeric = c("population", "n_hhlds",
                                            "med_hhld_inc", "n_workers", "n_workers_less_10k_inc",
                                            "n_workers_10to15k_inc", "n_workers_15to25k_inc",
                                            "n_workers_25to35k_inc", "n_workers_35to50k_inc",
                                            "n_workers_50to65k_inc", "n_workers_65to75k_inc",
                                            "n_workers_more_75k_inc")))  
  dt <- merge(dt, dt_acs, all.x = TRUE)
  
  fwrite(dt, file.path(outstub, "tract_demo_baseline.csv"))
}

load_geographies <- function(instub) {
  dt <- fread(file.path(instub, "census_block_master.csv"),
              select = list(character = c("block", "tract", "place_code", "place_name", 
                                          "countyfips", "county_name",
                                          "cbsa", "statefips"),
                            numeric = c("num_house10")))
    
  return(dt)
}

assemble_statutory_mw <- function(dt, dt_mw) {
  
  dt <- dt_mw$state[dt,  on = c("statefips",                "year", "month")][, event := NULL]
  dt <- dt_mw$county[dt, on = c("statefips", "county_name", "year", "month")][, event := NULL]
  dt <- dt_mw$local[dt,  on = c("statefips", "place_name",  "year", "month")][, event := NULL]
  
  # Compute statutory MW
  dt[, statutory_mw := pmax(local_mw, county_mw, state_mw, fed_mw, na.rm = T)]
  
  return(dt)
}

collapse_data <- function(dt, key_vars) {
  
  dt <- dt[, .(statutory_mw = weighted.mean(statutory_mw, num_house10),
               local_mw     = weighted.mean(local_mw,     num_house10),
               county_mw    = weighted.mean(county_mw,    num_house10),
               state_mw     = weighted.mean(state_mw,     num_house10),
               fed_mw       = weighted.mean(fed_mw,       num_house10)),
           keyby = key_vars]
  
  return(dt)
}

main()
