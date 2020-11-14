remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")

load_packages(c('tidyverse', 'data.table', 'matrixStats'))

main <- function() {
  
  #only problem now is that the base/demographic folder must run AFTER the base/zillow_min_wage, as it uses its output 
  mw_datadir <- "../../../base/zillow_min_wage/output/"
  outdir <- "../temp/"
  
  
  df <- fread("../../../raw/crosswalk/tract_place_xwalk.csv", 
              select = c('state', 'county', 'cntyname', 'tract', 'stab', 'placefp', 'placenm', 'afact'), 
              colClasses = c('character', 'character', 'character', 'character', 'character', 'character', 'character', 'numeric', 'numeric'))
  setnames(df, old = c('state', 'county', 'cntyname', 'stab', 'placefp', 'placenm'), 
           new = c('state_fips', 'county_fips', 'county', 'stateabb', 'place_fips', 'place'))
  df[, c('state_fips', 'county_fips', 'tract') := .(str_pad(as.character(state_fips), 2, pad = 0), 
                                                    str_pad(as.character(county_fips), 5, pad = 0), 
                                                    str_pad(as.character(as.numeric(tract)*100), 6, pad = 0))]
  df[, 'tract_fips' := paste0(county_fips, tract)]
  setorderv(df, c('state_fips', 'county_fips', 'tract', 'place_fips'))
  df <- df[df[, .I[which.max(afact)], by=tract_fips]$V1]
  df[, place := gsub("(.*),.*", "\\1", place)][, place := gsub("\\s*\\w*$", "", place)]
  df[, county := gsub("\\s*\\w*$", "", county)][, county := paste0(county, " County")]
  dfp <- CJ(df[['tract_fips']], c(2013:2018))
  setnames(dfp, new = c('tract_fips', 'year'))
  dfp <- dfp[df, on = 'tract_fips']

  mw_state <- fread(paste0(mw_datadir, "VZ_state_annual.csv"), 
                    select = c('statefips', 'year', 'fed_mw', 'mw'))
  setnames(mw_state, old = c('statefips', 'mw'), new = c('state_fips', 'state_mw'))
  mw_state[, state_fips := str_pad(as.character(state_fips), 2, pad = 0)]
  
  mw_substate <- fread(paste0(mw_datadir, "VZ_substate_annual.csv"))
  mw_substate[, locality := str_to_title(locality)]
  setnames(mw_substate, old = c('statefips'), new = c('state_fips'))
  mw_substate[, state_fips := str_pad(as.character(state_fips), 2, pad = 0)]
  mw_substate[,iscounty := str_extract_all(locality, " County")][,
                                                               iscounty := ifelse(iscounty == " County", 1, 0)]
  
  mw_vars <- names(mw_substate)
  mw_vars <- mw_vars[grepl("mw", mw_vars)]
  county_mw_vars <- paste0("county_", mw_vars)
  local_mw_vars <- paste0("local_", mw_vars)
  
  dfCountymw <- mw_substate[iscounty == 1,][,iscounty := NULL]
  setnames(dfCountymw, old = c('locality', mw_vars), 
           new = c('county', county_mw_vars))
  dfCountymw[, c('statename', 'stateabb') := NULL]
  
  
  dfLocalmw <- mw_substate[iscounty == 0,][,iscounty := NULL]
  setnames(dfLocalmw, old = c('locality', mw_vars),
           new = c('place', local_mw_vars))
  dfLocalmw[, c('statename', 'stateabb') := NULL]
  

  dfp <- mw_state[dfp, on = c('state_fips', 'year')]
  dfp <- dfCountymw[dfp, on = c('state_fips', 'county', 'year')]
  dfp <- dfLocalmw[dfp, on = c('state_fips', 'place', 'year')]
  
  mw_vars <- c('local_mw', 'county_mw', 'state_mw', 'fed_mw')
  
  dfp[,actual_mw := rowMaxs(as.matrix(dfp[,..mw_vars]), na.rm = T)][,actual_mw:= fifelse(actual_mw == -Inf, NA, actual_mw)]
  
  mw_avg1318 <- dfp[, .(mw1318 = mean(actual_mw, na.rm = T)), by = 'tract_fips']
  
  mw_avg1318[, c('mw_annual_ft', 'mw_annual_ft2', 'mw_annual_pt') := list(mw1318*40*4.35*12, mw1318*40*4.35*12*2, mw1318*20*4.35*12)]
  
  save_data(mw_avg1318, key = 'tract_fips', 
            filename = paste0(outdir,'mw_avg1318.csv'))
}

main()

