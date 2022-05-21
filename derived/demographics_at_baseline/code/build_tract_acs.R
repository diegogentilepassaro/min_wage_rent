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

  yy <- 2014
  mm <- 1

  dt_geo <- load_geographies(in_master)
  
  dt_mw  <- load_mw(in_mw_data)
  
  dt <- copy(dt_geo)
  dt[, c("year", "month") := .(yy, mm)]

  dt <- assemble_statutory_mw(dt, dt_mw)
  dt <- dt[, c("block", "tract", 
               "fed_mw", "state_mw", "county_mw", "local_mw", "statutory_mw",
               "num_house10")]
  dt <- collapse_data(dt)

  numeric_vars <- c("population", "n_hhlds", "med_hhld_inc", "n_workers",
                    paste0("n_workers_", c("less_10k_inc", "10to15k_inc", "15to25k_inc",
                                           "25to35k_inc",  "35to50k_inc", "50to65k_inc", 
                                           "65to75k_inc",  "more_75k_inc")))
  dt_acs <- fread(file.path(in_acs, "acs_tract_2014.csv"),
                  select = list(character = c("tract"),
                                numeric   = numeric_vars)  )
  dt <- merge(dt, dt_acs, all.x = TRUE)
  
  fwrite(dt, file.path(outstub, "tract.csv"))
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

collapse_data <- function(dt) {
  
  dt <- dt[, .(statutory_mw = weighted.mean(statutory_mw, num_house10),
               local_mw     = weighted.mean(local_mw,     num_house10),
               county_mw    = weighted.mean(county_mw,    num_house10),
               state_mw     = weighted.mean(state_mw,     num_house10),
               fed_mw       = weighted.mean(fed_mw,       num_house10)),
           keyby = .(tract)]
  
  return(dt)
}

main()
