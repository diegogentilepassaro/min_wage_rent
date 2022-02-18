remove(list = ls())

library(data.table)
library(zoo)
library(stringr)
source("../../../lib/R/save_data.R")

setDTthreads(20)

main <- function(){
   geocorr_dir  <- "../../../drive/raw_data/geocorr"
   base_geo_dir <- "../../../drive/base_large/census_block_master"
   base_mw_dir  <- "../../../base/min_wage/output"
   outstub      <- "../../../drive/derived_large/min_wage"
   log_file     <- "../output/data_file_manifest.log"
   
   if (file.exists(log_file)) file.remove(log_file)
   
   start_date <- "2009-07-01"
   end_date   <- "2020-01-31"
   
   county_names <- fread(file.path(geocorr_dir, "geocorr2018.csv"), 
                      colClasses = c("county" = "character")) %>%
     select(county, cntyname, stab, cbsaname10) %>%
     rename(countyfips = county,
            county_name = cntyname,
            state_abb = stab,
            cbsa10_name = cbsaname10)
   county_names <- county_names[!duplicated(county_names), ]
   
   dt <- fread(file.path(base_geo_dir, "census_block_master.csv"), 
               colClasses = c("census_block" = "character", "census_tract" = "character",
                              "zipcode"    = "character", "place_code" = "character", 
                              "countyfips" = "character", "statefips"  = "character", 
                              "cbsa10"     = "character", "place_name" = "character")) %>%
     select(-num_house10, -pop10, -rural, -place_type)
   dt <- left_join(dt, county_names, by = "countyfips")

   dt <- build_frame(dt, start_date, end_date)
   
   dt.mw <- load_mw(base_mw_dir)
   
   dt <- assemble_statutory_mw(dt, dt.mw)
   
   dt.zip    <- collapse_datatable(copy(dt), 
                                   key_vars = c("zipcode",    "year", "month"))
   dt.county <- collapse_datatable(copy(dt), 
                                   key_vars = c("countyfips", "year", "month"))
   
   save_data(dt.zip, key = c("zipcode", "year", "month"),
             filename = file.path(outstub, "zip_statutory_mw.csv"),
             logfile  = log_file)
   save_data(dt.zip, key = c("zipcode", "year", "month"),
             filename = file.path(outstub, "zip_statutory_mw.dta"),
             nolog    = TRUE)

   save_data(dt.county, key = c("countyfips", "year", "month"),
             filename = file.path(outstub, "county_statutory_mw.csv"),
             logfile  = log_file)
   save_data(dt.county, key = c("countyfips", "year", "month"),
             filename = file.path(outstub, "county_statutory_mw.dta"),
             nolog    = TRUE)

   dt.cf <- compute_counterfactual(dt.zip)
   
   save_data(dt.cf, key = c("zipcode", "year", "month"),
             filename = file.path(outstub, "zipcode_cfs.csv"),
             logfile  = log_file)
   save_data(dt.cf, key = c("zipcode", "year", "month"),
             filename = file.path(outstub, "zipcode_cfs.dta"),
             nolog    = TRUE)
}

build_frame <- function(dt, start_date, end_date, freq = "month") {
   
   dt[, county_name    := gsub("\\s*\\w*$", " County", dt$county_name)]
   dt[, place_name := gsub(",\\s*\\w*$", "", dt$place_name)]     # Drop final state abb after comma, e.g. ", MA" 
   dt[, place_name := gsub("\\s*\\w*$", "",  dt$place_name)]     # Drop final word "city"
   
   dt <- manual_corrections(dt)
   
   dt[, c('from', 'to') := list(as.Date(start_date), 
                                as.Date(end_date))]
   
   dt <- dt[, list(census_block, census_tract,
                   zcta, zipcode, place_code, place_name, countyfips, county_name,
                   statefips, state_abb, cbsa10, cbsa10_name,
                   daily_date = seq(from, to, by = freq)), 
              by = 1:nrow(dt)][, nrow := NULL]
   
   dt[, c('year', 'month') :=  .(as.numeric(format(as.Date(daily_date), "%Y")),
                                 as.numeric(format(as.Date(daily_date), "%m")))]
   dt[, year_month := as.yearmon(daily_date)]
   dt[, daily_date := NULL]
   
   return(dt)
}

manual_corrections <- function(dt) {
  
   dt[place_name == 'Louisville/Jefferson County metro government (balance)', 
      place_name := 'Lousville']
   dt[place_name == 'New York',  place_name := 'New York City']
   dt[place_name == 'St. Paul',  place_name := 'Saint Paul']
   dt[place_name == 'Daly city', place_name := 'Daly City']
   
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
   
   county_mw <- county_mw[, .(county_name,    statefips, county_mw,
                              county_abovestate_mw, year, month)]
   local_mw <- local_mw[,   .(place_name, statefips, local_mw, 
                              local_abovestate_mw,  year, month)]
   
   return(list("state"  = state_mw, 
               "county" = county_mw, 
               "local"  = local_mw))
}

assemble_statutory_mw <- function(dt, dt.mw) {
   
   dt <- dt.mw$state[dt,  
                     on = c("statefips", "year", "month")]
   dt <- dt.mw$county[dt, 
                           on = c("county_name",    "statefips", "year", "month")]
   dt <- dt.mw$local[dt,  
                     on = c("place_name", "statefips", "year", "month")]
   
   # Compute statutory_mw MW
   dt[, statutory_mw := pmax(local_mw, county_mw, state_mw, fed_mw, na.rm = T)]
   dt[, binding_mw := fcase(
      pmax(local_mw, county_mw, state_mw, fed_mw, na.rm = T) == fed_mw,    1,  # Fed MW
      pmax(local_mw, county_mw, state_mw, fed_mw, na.rm = T) == state_mw,  2,  # State MW
      pmax(local_mw, county_mw, state_mw, fed_mw, na.rm = T) == county_mw, 3,  # County MW
      pmax(local_mw, county_mw, state_mw, fed_mw, na.rm = T) == local_mw,  4,  # City MW
      default = NA
   )]
   
   dt[, statutory_mw_ignore_local := pmax(state_mw, fed_mw, na.rm = T)]
   dt[, binding_mw_ignore_local := fcase(
      pmax(state_mw, fed_mw, na.rm = T) == fed_mw,    1,  # Fed MW
      pmax(state_mw, fed_mw, na.rm = T) == state_mw,  2,  # State MW
      default = NA
   )]
   
   return(dt)
}

collapse_datatable <- function(dt, key_vars = c("zipcode", "year", "month")) {
   
   dt <- dt[, .(statutory_mw                   = max(statutory_mw),
                statutory_mw_ignore_local      = max(statutory_mw_ignore_local),
                statutory_mw_mean              = mean(statutory_mw),
                statutory_mw_ignore_local_mean = mean(statutory_mw_ignore_local),
                binding_mw                     = first(binding_mw),
                binding_mw_ignore_local        = first(binding_mw_ignore_local),
                local_mw                       = max(local_mw),
                state_mw                       = max(state_mw),
                fed_mw                         = max(fed_mw)),
            by = key_vars]
   
   mw_vars <- names(dt)[grepl("mw", names(dt)) & !grepl("abovestate", names(dt))]
   vars_to_keep <- c(key_vars, mw_vars)
   
   dt <- dt[, ..vars_to_keep]
   
   return(dt)
}

compute_counterfactual <- function(dt) {

   dt.last <- dt[year == 2019 & month == 12]
   dt.cf   <- copy(dt.last)
   dt.cf[, c("year", "month") := list(2020, 1)]

   dt <- rbindlist(list(dt.last, dt.cf))

   dt[, fed_mw_cf_10pc  := fed_mw*1.1]
   dt[, fed_mw_cf_9usd  := 9]
   dt[, fed_mw_cf_15usd := 15]

   dt[, statutory_mw_cf_10pc  := fcase(year == 2019 & month == 12, statutory_mw,
                                    year == 2020 & month ==  1, pmax(statutory_mw, fed_mw_cf_10pc))]
   dt[, statutory_mw_cf_9usd  := fcase(year == 2019 & month == 12, statutory_mw,
                                    year == 2020 & month ==  1, pmax(statutory_mw, fed_mw_cf_9usd))]
   dt[, statutory_mw_cf_15usd := fcase(year == 2019 & month == 12, statutory_mw,
                                    year == 2020 & month ==  1, pmax(statutory_mw, fed_mw_cf_15usd))]

   return(dt)
}

main()
