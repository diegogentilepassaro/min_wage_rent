remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")

load_packages(c("data.table", "zoo", "stringr"))

main <- function(){
   base_geo_dir <- "../../../base/geo_master/output"
   base_mw_dir  <- "../../../base/min_wage/output"
   tempdir      <- "../temp"
   log_file     <- "../output/data_file_manifest.log"
   
   if (file.exists(log_file)) file.remove(log_file)
   
   start_date <- "2010-01-01"
   end_date   <- "2019-12-31"
   
   dt <- build_frame(base_geo_dir, start_date, end_date)
   
   dt.mw <- load_mw(base_mw_dir)
   
}

build_frame <- function(instub, start_date, end_date, freq = "month") {
   
   dt <- fread(file.path(instub, "zip_county_place_usps_master.csv"))
   
   setnames(dt, old = c('state_abb', 'place_name', 'county_name'), 
                new = c('stateabb',  'placename',  'county'))
   
   dt[, county    := gsub("\\s*\\w*$", " County", dt$county)]
   dt[, placename := gsub(",\\s*\\w*$", "", dt$placename)]
   dt[, placename := gsub("\\s*\\w*$", "",  dt$placename)]
   
   key_vars <- c("zipcode", "place_code", "countyfips")
   dt <- unique(dt, by = key_vars)
   
   dt[, c('from', 'to') := list(as.Date(start_date), 
                                as.Date(end_date))]
   
   dt <- manual_corrections(dt)
   
   dt <- dt[, list(zcta, zipcode, place_code, placename, countyfips, county,
                   stateabb, cbsa10, cbsa10_name, houses_zcta_place_county,
                   daily_date = seq(from, to, by = freq)), 
              by = key_vars]
   
   dt[, c('year', 'month') :=  .(as.numeric(format(as.Date(daily_date), "%Y")),
                                 as.numeric(format(as.Date(daily_date), "%m")))]
   
   if (freq == "month") {
      dt[, year_month := as.yearmon(daily_date)]
      dt[, daily_date := NULL]
   }
   
   return(dt)
}

manual_corrections <- function(dt) {
   dt[placename == 'Louisville/Jefferson County metro government (balance)', placename := 'Lousville']
   dt[placename == 'New York',      placename := 'New York City']
   dt[placename == 'St. Paul',      placename := 'Saint Paul']
   dt[placename == 'Daly City',     placename := 'Daly City']
   dt[placename == 'Readwood City', placename := 'Redwood City']
   
   return(dt)
}

load_mw <- function(instub) {
   
   # State MW
   state_mw <- fread(file.path(instub, "state_monthly.csv"))
   
   setnames(state_mw, old = c("monthly_date", "mw"), 
                      new = c("date",         "state_mw"))
   
   state_mw[, c("year", "month") := .(as.numeric(substr(date, 1, 4)),
                                      as.numeric(gsub("m", "", substr(date, 5, length(date)))))]
   state_mw[, c("date", "statename") := NULL]
   
   state_mw[, statefips := str_pad(as.character(statefips), 2, pad = 0)]
   
   # Substate MW
   local_mw <- fread(file.path(instub, "substate_monthly.csv"))
   
   setnames(local_mw, old = c("monthly_date"), new = c("date"))
   
   local_mw[, c("year", "month") := .(as.numeric(substr(date, 1, 4)),
                                      as.numeric(gsub("m", "", substr(date, 5, length(date)))))]
   local_mw[, c("date", "statename") := NULL]

   local_mw[, statefips := str_pad(as.character(statefips), 2, pad = 0)]
   local_mw[, iscounty  := 1*grepl("County", locality)]
   
   mw_vars        <- names(local_mw)[grepl("mw", names(local_mw))]
   county_mw_vars <- paste0("county_", mw_vars)
   local_mw_vars  <- paste0("local_",  mw_vars)
   
   county_mw <- local_mw[iscounty == 1, ][, iscounty := NULL]
   setnames(county_mw, old = c('locality', mw_vars), 
                       new = c('county',   county_mw_vars))
   
   local_mw <- local_mw[iscounty == 0, ][, iscounty := NULL]
   setnames(local_mw, old = c('locality',  mw_vars),
                      new = c('placename', local_mw_vars))
   
   county_mw <- county_mw[, .(county,    statefips, stateabb, county_mw,  # Keep max of local MWs
                              county_abovestate_mw, year, month)]
   local_mw <- local_mw[,   .(placename, statefips, stateabb, local_mw, 
                              local_abovestate_mw,  year, month)]
   
   return(list('state'  = state_mw, 
               'county' = county_mw, 'local' = local_mw))
}

main()
