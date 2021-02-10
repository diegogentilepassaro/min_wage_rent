remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")

options(scipen=999)
load_packages(c('tidyverse', 'data.table', 'bit64', 'purrr', 'readxl', 'parallel', 'matrixStats', 'readstata13'))


main <- function() {
  datadir_mw     <- '../../../base/min_wage/output/'
  datadir_xwalk  <- '../../../raw/crosswalk/'
  datadir_mxwalk <- '../../geo_master/output/'
  outdir         <- '../../../drive/base_large/output/'
  log_file       <- "../output/mw_file_manifest.log"

  mw_data <- load_mw(instub = datadir_mw)
  state_mw <- mw_data[['state_mw']]
  county_mw <- mw_data[['county_mw']]
  local_mw <- mw_data[['local_mw']]
  
  mxwalk <- make_mxwalk(instub = datadir_mxwalk)

  zipmw_us <- assemble_mw_US(mxwalk = mxwalk, 
                               stmw   = state_mw, 
                               ctymw  = county_mw, 
                               locmw  = local_mw)  
  zipmw_us <- zipmw_us[, .(year_month, zipcode, placename, countyfips, county, statefips, stateabb, 
                           fed_mw, state_mw, county_mw, local_mw, county_abovestate_mw, local_abovestate_mw, 
                           actual_mw, dactual_mw, treated_mw)][!is.na(zipcode),]
  
 save_data(zipmw_us, 
           key = c('zipcode', 'year_month'), 
           filename = paste0(outdir, 'zip_mw.dta'), 
           logfile = log_file) 

}


load_mw <- function(instub) {
  #load MW data
  state_mw <- fread(paste0(instub, 'VZ_state_monthly.csv'))
  setnames(state_mw, old = c('monthly_date', 'mw'), new = c('date', 'state_mw'))
  state_mw[,date := str_replace_all(date, "m", "_")][
    ,year_month := as.Date(paste0(date, "_01"), "%Y_%m_%d")][
      ,c('date', 'statename'):=NULL]
  state_mw[,statefips := str_pad(as.character(statefips), 2, pad = 0)]
  
  local_mw <- fread(paste0(instub, 'VZ_substate_monthly.csv'))
  setnames(local_mw, old = c('monthly_date'), new = c('date'))
  local_mw[,date := str_replace_all(date, "m", "_")][
    ,year_month := as.Date(paste0(date, "_01"), "%Y_%m_%d")][
      ,date:=NULL]
  local_mw[,statefips := str_pad(as.character(statefips), 2, pad = 0)]
  local_mw[,iscounty := str_extract_all(locality, " County")][,
                                                              iscounty := ifelse(iscounty == " County", 1, 0)]
  mw_vars <- names(local_mw)
  mw_vars <- mw_vars[grepl("mw", mw_vars)]
  
  county_mw_vars <- paste0("county_", mw_vars)
  local_mw_vars <- paste0("local_", mw_vars)
  
  
  county_mw <- local_mw[iscounty == 1,][,iscounty := NULL]
  setnames(county_mw, old = c('locality', mw_vars), 
           new = c('county', county_mw_vars))
  county_mw <- county_mw[, .(county, statefips, stateabb, county_mw, county_abovestate_mw, year_month)]
  
  local_mw <- local_mw[iscounty == 0,][,iscounty := NULL]
  setnames(local_mw, old = c('locality', mw_vars),
           new = c('placename', local_mw_vars))
  local_mw <- local_mw[, .(placename, stateabb, statefips, local_mw, local_abovestate_mw, year_month)]
  
  return(list('state_mw' = state_mw, 'county_mw' = county_mw, 'local_mw' = local_mw))
}

make_mxwalk <- function(instub) {
  df <- setDT(read.dta13(paste0(instub, 'zcta_county_place_usps_master_xwalk.csv')))

  df <- df[df[, .I[houses_zcta_place_county == max(houses_zcta_place_county)], by = 'zipcode']$V1] 
  df <- df[df[, .I[1], by = 'zipcode']$V1] #when duplicate zip code, keep the one assigned to a city (as opposed to rural area with code 99999)
  
  setnames(df, old = c('state_abb', 'place_name', 'county_name'), new = c('stateabb', 'placename', 'county'))
  
  df[, county := gsub("\\s*\\w*$", " County", df$county)]
  df[, placename := gsub(",\\s*\\w*$", "", df$placename)][, placename := gsub("\\s*\\w*$", "", df$placename)]
  
  df <- manual_correction(df)
  
  return(df)
}

manual_correction <- function(data) {
  data[placename=='Louisville/Jefferson County metro government (balance)', placename := 'Lousville']
  data[placename=='New York', placename := 'New York City']
  data[placename=='Redwood City', placename := 'Readwood City']
  data[placename=='St. Paul', placename := 'Saint Paul']
  data[placename=='Daly City', placename := 'Daly city']
  #data[zipcode=='94608', placename := 'Emeryville']
}

assemble_mw_US <- function(mxwalk, stmw, ctymw, locmw) {
  geovars <- c('zipcode', 
               'placename', 'place_code', 
               'cbsa10', 'cbsa10_name', 
               'countyfips', 'county', 
               'statefips', 'stateabb')
  dfzip <- mxwalk[, ..geovars]
  
  dfzip[, c('from', 'to') := .(as.Date('2010-01-01'), as.Date('2019-12-01'))]
  dfzip <- dfzip[, list(zipcode, 
                     placename, place_code, 
                     cbsa10, cbsa10_name, 
                     countyfips, county, 
                     statefips, stateabb,
                     year_month = seq(from, to, by = 'month')), 
                 by = 1:nrow(dfzip)][, nrow :=NULL]
  
  
  dfzip <- stmw[dfzip, on = c('stateabb', 'statefips', 'year_month')]
  dfzip <- ctymw[dfzip, on = c('county', 'statefips', 'stateabb', 'year_month')]
  dfzip <- locmw[dfzip, on = c('placename', 'statefips', 'stateabb', 'year_month')]
  
  #compute actual MW
  mw_vars <- names(dfzip)
  mw_vars <- mw_vars[grepl("mw", mw_vars)]
  mw_vars <- mw_vars[!grepl("abovestate", mw_vars)]
  
  dfzip[,actual_mw := rowMaxs(as.matrix(dfzip[,..mw_vars]), na.rm = T)][
    ,actual_mw := ifelse(actual_mw == -Inf, NA, actual_mw)]
  dfzip[, dactual_mw := actual_mw - shift(actual_mw, type = 'lag'), by = 'zipcode']
  dfzip[, treated_mw := fifelse(dactual_mw>0, 1, 0, na = 0)]
  dfzip[, zipcode:=as.numeric(zipcode)] 
  return(dfzip)
}


main()