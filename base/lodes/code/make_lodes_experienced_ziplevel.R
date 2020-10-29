remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")

options(scipen=999)
load_packages(c('tidyverse', 'data.table', 'bit64', 'purrr', 'readxl', 'parallel', 'matrixStats', 'usmap'))

main <- function(){
  datadir_lodes <- '../../../drive/base_large/output/'
  datadir_mw    <- '../../../base/zillow_min_wage/output/'
  datadir_xwalk <- '../../../raw/crosswalk/'
  outdir        <- '../../../drive/base_large/output/'
  
  mw_data <- load_mw(instub = datadir_mw)
  state_mw <- mw_data[['state_mw']]
  county_mw <- mw_data[['county_mw']]
  local_mw <- mw_data[['local_mw']]
  
  xwalks <- make_xwalks(instub = datadir_mw)
  zip_county <- xwalks[['zip_county']]
  zip_places <- xwalks[['zip_places']]
  
  zipmw_us <- assemble_mw_US(zcounty = zip_county, 
                             zplaces = zip_places, 
                             stmw    = state_mw, 
                             ctymw   = county_mw, 
                             locmw   = local_mw)
  
  target_period <- unique(zipmw_us[['yearmonth']])
  
  #compute for, for each state, share of treated and experienced MW (mclapply?)
  state_fips <- fips(c(tolower(state.abb), 'dc'))
  
  exp_mw <- mclapply(state_fips, 
                     function(x, p = target_period, zip = zipmw_us) {
                       this_state <- fread(paste0(datadir_lodes, 'odzip_', x, '.csv'))
                       this_state[, c('h_totjob', 'h_job_young', 'h_job_lowinc') := lapply(.SD, sum, na.rm = T) , 
                                  .SDcols = c('totjob', 'job_young', 'job_lowinc'), 
                                  by = 'h_zipcode']
                       setorderv(this_state, cols = c('h_zipcode', 'w_zipcode'))
                       #share of treated and experienced MW for every date (mclapply)
                       p <- lapply(p, function(y, this_st = this_state, zip2 = zip) {
                         this_date_mw <- zip2[yearmonth==y,][, 'w_zipcode' := zipcode]
                         this_state_date <- this_date_mw[, .(w_zipcode, actual_mw, treated_mw, yearmonth)][this_st, on = 'w_zipcode']
                         this_state_date[treated_mw==1, c('sh_treated_totjob', 'sh_treated_job_young', 'sh_treated_job_lowinc') := lapply(.SD, sum, na.rm = T)
                                         , .SDcols = c('totjob', 'job_young', 'job_lowinc'), by = 'h_zipcode'][
                                           , c('sh_treated_totjob', 'sh_treated_job_young', 'sh_treated_job_lowinc') := lapply(.SD, max, na.rm = T)
                                           , .SDcols = c('sh_treated_totjob', 'sh_treated_job_young', 'sh_treated_job_lowinc'), by = 'h_zipcode'][
                                             , c('sh_treated_totjob', 'sh_treated_job_young', 'sh_treated_job_lowinc') := replace(.SD, .SD==-Inf, 0)
                                             , .SDcols = c('sh_treated_totjob', 'sh_treated_job_young', 'sh_treated_job_lowinc')]
                         this_state_date[, c('sh_treated_totjob', 'sh_treated_job_young', 'sh_treated_job_lowinc') := 
                                           .((sh_treated_totjob / h_totjob), (sh_treated_job_young / h_job_young), (sh_treated_job_lowinc / h_job_lowinc))]
                         
                         this_state_date[, c('sh_totjob', 'sh_job_young', 'sh_job_lowinc') := 
                                           .((totjob / h_totjob), (job_young / h_job_young), (job_lowinc / h_job_lowinc))]
                         
                         this_state_date <- this_state_date[, .(sh_treated_totjob = first(sh_treated_totjob), 
                                                                sh_treated_job_young = first(sh_treated_job_young), 
                                                                sh_treated_job_lowinc = first(sh_treated_job_lowinc), 
                                                                exp_mw_totjob = sum(actual_mw*sh_totjob, na.rm = T), 
                                                                exp_mw_job_young = sum(actual_mw*sh_job_young, na.rm = T), 
                                                                exp_mw_job_lowinc = sum(actual_mw*sh_job_lowinc, na.rm = T)), by = c('h_zipcode', 'yearmonth')]
                         this_state_date <- this_state_date[!is.na(yearmonth),]
                         return(this_state_date)
                       })
                       p <- rbindlist(p)
                       return(p)
                     }, mc.cores = 8)
  exp_mw <- rbindlist(exp_mw)
  setnames(exp_mw, old  = 'h_zipcode', new = 'zipcode')
  setorderv(exp_mw, c('zipcode', 'yearmonth'))
  
  save_data(exp_mw, key = c('zipcode', 'yearmonth'), filename = paste0(outdir, 'exp_mw.dta'))
  
}



load_mw <- function(instub) {
  #load MW data
  state_mw <- fread(paste0(instub, 'VZ_state_monthly.csv'))
  setnames(state_mw, old = c('monthly_date', 'mw'), new = c('date', 'state_mw'))
  state_mw[,date := str_replace_all(date, "m", "_")][
    ,yearmonth := as.Date(paste0(date, "_01"), "%Y_%m_%d")][
      ,c('date', 'statename'):=NULL]
  state_mw[,statefips := str_pad(as.character(statefips), 2, pad = 0)]
  
  local_mw <- fread(paste0(instub, 'VZ_substate_monthly.csv'))
  setnames(local_mw, old = c('monthly_date'), new = c('date'))
  local_mw[,date := str_replace_all(date, "m", "_")][
    ,yearmonth := as.Date(paste0(date, "_01"), "%Y_%m_%d")][
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
  county_mw <- county_mw[, .(county, statefips, stateabb, county_mw, county_abovestate_mw, yearmonth)]
  
  local_mw <- local_mw[iscounty == 0,][,iscounty := NULL]
  setnames(local_mw, old = c('locality', mw_vars),
           new = c('placename', local_mw_vars))
  local_mw <- local_mw[, .(placename, stateabb, statefips, local_mw, local_abovestate_mw, yearmonth)]
  
  return(list('state_mw' = state_mw, 'county_mw' = county_mw, 'local_mw' = local_mw))
}

make_xwalks <- function(instub) {
  #create crosswalks for all MW files to usps zipcode
  zip_to_zcta <- readxl::read_excel('../../../raw/crosswalk/zip_to_zcta_2019.xlsx')
  setnames(zip_to_zcta, old = c('ZIP_CODE', 'ZCTA'), new = c('zipcode', 'zcta'))
  zip_to_zcta <- zip_to_zcta[,c('zipcode', 'zcta')]
  
  place <- fread(paste0(instub, 'places10.csv'))
  setnames(place, old = c("state"), new = c("statefips"))
  place[,statefips := str_pad(as.character(statefips), 2, pad = 0)]
  place[,place_code := str_pad(as.character(place_code), 5, pad = 0)]
  zip_places <- fread(paste0(instub, 'zip_places10.csv'), 
                      colClasses = c("place_code" = "character", "zcta" = "character",
                                     "statefips"  = "character"))
  setorder(zip_places, zcta)
  zip_places <- place[zip_places, on = c('statefips', 'place_code')]
  zip_places <- zip_places[pct_zip_houses_inplace >= 50,]
  zip_places <- left_join(zip_places, zip_to_zcta, by = c('zcta'))
  
  zip_county <- fread(paste0(instub, 'zip_county10.csv'), 
                      colClasses = c("zcta" = "character", "statefips" = "character",
                                     "county_code" = "character", "countyfips" = "character"))
  setorder(zip_county, zcta)
  
  zip_county <- zip_county[pct_zip_houses_incounty >= 50,]
  zip_county[,ind := max(pct_zip_pop_incounty, na.rm = T),by = 'zcta'][,
                                                                       ind := ifelse(ind == pct_zip_pop_incounty, 1, 0)]
  
  zip_county <- zip_county[ind == 1,]
  zip_county <- zip_county[,ind := NULL]
  zip_county <- left_join(zip_county, zip_to_zcta, by = c('zcta'))
  
  return(list('zip_county' = zip_county, 'zip_places' = zip_places))
}

assemble_mw_US <- function(zcounty, zplaces, stmw, ctymw, locmw) {
  # assemble MW for all US zipcodes 
  dfzip <- zcounty[, .(zipcode, countyfips, county, statefips, stateabb)]
  dfzip <- zplaces[, .(zipcode, placename, statefips)][dfzip, on = c('zipcode', 'statefips')]
  dfzip[, c('from', 'to') := .(as.Date('2010-01-01'), as.Date('2019-12-01'))]
  
  dfzip <- dfzip[, list(zipcode, placename, countyfips, county, statefips, stateabb, yearmonth = seq(from, to, by = 'month')), 
                 by = 1:nrow(dfzip)][, nrow :=NULL]
  dfzip <- stmw[dfzip, on = c('stateabb', 'statefips', 'yearmonth')]
  dfzip <- ctymw[dfzip, on = c('county', 'statefips', 'stateabb', 'yearmonth')]
  dfzip <- locmw[dfzip, on = c('placename', 'statefips', 'stateabb', 'yearmonth')]
  
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
