remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")

load_packages(c('haven', 'dplyr', 'truncnorm'))

set.seed(42)

main <- function() {
  infile <- "../../../drive/derived_large/output/zipcode_yearmonth_panel_all.dta"
  
  DF <- load_data(infile)
  
  DF <- simulate_rents(DF, var = "medrentprice_sfcc")
  
}

load_data <- function(file) {
  
  DF <- read_dta(file)
  
  DF <- DF[, c("zipcode", "year_month", "zcta", "placetype", "countyfips", "statefips", "msa",
               "fed_mw", "state_mw", "county_mw", "local_mw", "actual_mw", "dactual_mw",
               "mw_event", "sal_mw_event", "mw_event025", "mw_event075",
               "medrentprice_sfcc", "medrentpricepsqft_sfcc", "medlistingprice_sfcc", "medlistingpricepsqft_sfcc",
               "pct_zip_houses_incounty", "pct_zip_pop_incounty", "pop10_zip_county")]
  
  DF <- DF %>% filter(!is.na(countyfips))  # remove places with NA county

  # Data checks
  stopifnot(!any(is.na(DF[, c('zipcode')])))
  stopifnot(!any(is.na(DF[, c('countyfips')])))
  stopifnot(!any(is.na(DF[, c('statefips')])))
  
  return(DF)
}

simulate_rents <- function(DF, var) {
  
  # keep zipcodes with valid rent var
  DF <- DF %>% group_by(zipcode) %>% filter(any(!is.na(var)))
  
  # Define objects
  sd_r = sapply(DF[, c(var)],          sd,  na.rm = T)
  min_r = ceiling(sapply(DF[, c(var)], min, na.rm = T))
  max_r = ceiling(sapply(DF[, c(var)], max, na.rm = T))
  
  zipcodes = unique(DF[, c('zipcode')])
  counties = unique(DF[, c('countyfips')])
  states   = unique(DF[, c('statefips')])
  
  # Zipcode effects
  zipcodes_avgs = aggregate(DF[, var], by = list(DF$zipcode), FUN = mean, na.rm = T)
  names(zipcodes_avgs) <- c("zipcode", "zipcode_avg")
  
  zipcodes <- merge(zipcodes, zipcodes_avgs, by = 'zipcode')
  
  DF[, ""]
  
}


simulate_housing_values <- function() {
  
  
}


main

