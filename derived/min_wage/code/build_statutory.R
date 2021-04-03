remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")

load_packages(c("data.table", "zoo", "stringr"))

main <- function(){
   base_geo_dir <- "../../../base/geo_master/output"
   base_mw_dir  <- "../../../base/min_wage/output"
   outstub      <- "../../../drive/derived_large/min_wage"
   log_file     <- "../output/data_file_manifest.log"
   
   if (file.exists(log_file)) file.remove(log_file)
   
   start_date <- "2010-01-01"
   end_date   <- "2019-12-31"
   
   dt <- build_frame(base_geo_dir, start_date, end_date)
   
   dt.mw <- load_mw(base_mw_dir)
   
   dt <- assemble_statutory_mw(dt, dt.mw)
   
   dt.zip    <- collapse_datatable(copy(dt), key_vars = c("zipcode",    "year", "month"))
   dt.county <- collapse_datatable(copy(dt), key_vars = c("countyfips", "year", "month"))
   
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
}

build_frame <- function(instub, start_date, end_date, freq = "month") {
   
   dt <- fread(file.path(instub, "zip_county_place_usps_all.csv"))
   
   dt[, statefips := str_pad(as.character(statefips), 2, pad = 0)]
   
   setnames(dt, old = c('state_abb', 'place_name', 'county_name'), 
                new = c('stateabb',  'placename',  'county'))
   
   dt[, county    := gsub("\\s*\\w*$", " County", dt$county)]
   dt[, placename := gsub(",\\s*\\w*$", "", dt$placename)]     # Drop final state abb after comma, e.g. ", MA" 
   dt[, placename := gsub("\\s*\\w*$", "",  dt$placename)]     # Drop final word "city"
   
   dt <- manual_corrections(dt)
   
   dt[, c('from', 'to') := list(as.Date(start_date), 
                                as.Date(end_date))]
   
   dt <- dt[, list(zcta, zipcode, place_code, placename, countyfips, county,
                   statefips, stateabb, cbsa10, cbsa10_name, houses_zcta_place_county,
                   daily_date = seq(from, to, by = freq)), 
              by = 1:nrow(dt)][, nrow := NULL]
   
   dt[, c('year', 'month') :=  .(as.numeric(format(as.Date(daily_date), "%Y")),
                                 as.numeric(format(as.Date(daily_date), "%m")))]
   dt[, year_month := as.yearmon(daily_date)]
   dt[, daily_date := NULL]
   
   return(dt)
}

manual_corrections <- function(dt) {
   dt[placename == 'Louisville/Jefferson County metro government (balance)', placename := 'Lousville']
   dt[placename == 'New York',      placename := 'New York City']
   dt[placename == 'St. Paul',      placename := 'Saint Paul']
   dt[placename == 'Daly city',     placename := 'Daly City']
   
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
                       new = c("county",   county_mw_vars))
   
   local_mw <- local_mw[iscounty == 0, ][, iscounty := NULL]
   setnames(local_mw, old = c("locality",  mw_vars),
                      new = c("placename", local_mw_vars))
   
   county_mw <- county_mw[, .(county,    statefips, county_mw,
                              county_abovestate_mw, year, month)]
   local_mw <- local_mw[,   .(placename, statefips, local_mw, 
                              local_abovestate_mw,  year, month)]
   
   return(list("state"  = state_mw, 
               "county" = county_mw, "local" = local_mw))
}

assemble_statutory_mw <- function(dt, dt.mw) {
   
   dt <- dt.mw$state[dt,  on = c(             "statefips", "year", "month")]
   dt <- dt.mw$county[dt, on = c("county",    "statefips", "year", "month")]
   dt <- dt.mw$local[dt,  on = c("placename", "statefips", "year", "month")]
   
   # Compute actual MW
   dt[, actual_mw := pmax(local_mw, county_mw, state_mw, fed_mw, na.rm = T)]
   dt[, binding_mw := fcase(
      pmax(local_mw, county_mw, state_mw, fed_mw, na.rm = T) == fed_mw,    1,  # Fed MW
      pmax(local_mw, county_mw, state_mw, fed_mw, na.rm = T) == state_mw,  2,  # State MW
      pmax(local_mw, county_mw, state_mw, fed_mw, na.rm = T) == county_mw, 3,  # County MW
      pmax(local_mw, county_mw, state_mw, fed_mw, na.rm = T) == local_mw,  4,  # City MW
      default = NA
   )]
   
   dt[, actual_mw_ignore_local := pmax(state_mw, fed_mw, na.rm = T)]
   dt[, binding_mw_ignore_local := fcase(
      pmax(state_mw, fed_mw, na.rm = T) == fed_mw,    1,  # Fed MW
      pmax(state_mw, fed_mw, na.rm = T) == state_mw,  2,  # State MW
      default = NA
   )]
   
   return(dt)
}

collapse_datatable <- function(dt, key_vars = c("zipcode", "year", "month")) {
   
   # Don't use zip_max_houses var here, to be robust to collapsing at county level
   setorder(dt, zipcode, -houses_zcta_place_county)
   dt.max <- dt[, first(.SD), by = key_vars]
   
   if (any("zipcode" %in% key_vars)) dt.max[, zip_max_houses := NULL]
   
   dt.wmean <- dt[, .(actual_mw_wg_mean              = weighted.mean(actual_mw, houses_zcta_place_county),
                      actual_mw_ignore_local_wg_mean = weighted.mean(actual_mw_ignore_local, houses_zcta_place_county)),
                  by = key_vars]
   
   dt <- dt.wmean[dt.max, on = key_vars]
   
   mw_vars <- names(dt)[grepl("mw", names(dt)) & !grepl("abovestate", names(dt))]
   vars_to_keep <- c(key_vars, "year_month", mw_vars)
   dt <- dt[, ..vars_to_keep]
   
   return(dt)
}

main()
