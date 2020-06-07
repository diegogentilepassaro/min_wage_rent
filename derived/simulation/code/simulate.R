remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")

load_packages(c('haven', 'dplyr'))

set.seed(42)

main <- function() {
  infolder  <- "../../../drive/derived_large/output"
  outfolder <- "../../../drive/derived_large/output"
  logfolder <- "../output"
  
  DF <- load_data(sprintf("%s/zipcode_yearmonth_panel_all.dta", infolder))
  
  DF <- simulate_rents(DF, var = "medrentprice_sfcc")
  
  save_data(DF, key = c("zipcode", "year_month"), 
            filename = sprintf("%s/simulated_zipcode_yearmonth_panel.dta", outfolder),
            logfile  = sprintf("%s/data_file_manifest.dta", logfolder))
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
  
  # Parameters
  hs_week = 40
  week_month = 4.35
  mw_earners = 2
  
  sd_shock = 100
  theta    = 0.1 # passthrough
  
  
  DF <- prepare_DF(DF)
  
  size_df = dim(DF)[1]
  
  # Define objects
  mean_r = sapply(DF[, c(var)], mean, na.rm = T)
  sd_r   = sapply(DF[, c(var)], sd,  na.rm = T)
  min_r  = ceiling(sapply(DF[, c(var)], min, na.rm = T))
  max_r  = ceiling(sapply(DF[, c(var)], max, na.rm = T))
  
  zipcodes = unique(DF[, c('zipcode')])
  counties = unique(DF[, c('countyfips')])
  states   = unique(DF[, c('statefips')])
  year_months = unique(DF[, c('year_month')]) - sapply(DF[, c('year_month')], mean, na.rm = T)
  
  
  # Zipcode effect
  zipcodes_avgs = aggregate(DF[, var], by = list(DF$zipcode), FUN = mean, na.rm = T)
  names(zipcodes_avgs) <- c("zipcode", "zipcode_effect")
  
  zipcodes <- merge(zipcodes, zipcodes_avgs, by = 'zipcode')
  DF <- merge(DF, zipcodes, by = 'zipcode')
  
  # Year-month effect
  period_avgs = aggregate(DF[, var], by = list(DF$zipcode), FUN = mean, na.rm = T)
  names(period_avgs) <- c("year_month", "timeperiod_effect")
  
  year_months <- merge(year_months, period_avgs, by = 'year_month')
  DF <- merge(DF, year_months, by = 'year_month')
  
  # Min wage effect
  DF$d_wage_rep_hh <- DF$dactual_mw*hs_week*week_month*mw_earners
  DF$mw_effect <- theta*DF$d_wage_rep_hh
  
  # iid shock
  DF$shock <- rnorm(size_df, mean = 0, sd = sd_shock)
  
  
  
  
  # SIMULATE
  DF$rent1 <- DF$zipcode_effect + DF$timeperiod_effect + DF$shock
  DF$rent1 <- ifelse(DF$rent1 < min_r, min_r, ifelse(DF$rent1 > max_r, max_r, DF$rent1))
  
  DF$rent2 <- DF$mw_effect + DF$zipcode_effect + DF$timeperiod_effect + DF$shock
  DF$rent2 <- ifelse(DF$rent2 < min_r, min_r, ifelse(DF$rent2 > max_r, max_r, DF$rent2))
  
  
}


prepare_DF <- function(DF) {
  DF <- DF %>% group_by(zipcode) %>% filter(any(!is.na(eval(parse(text=var)))))
  DF <- DF[(DF$year_month >= 596) & (DF$year_month <= 715),]
  
  DF[is.na(DF$sal_mw_event), "sal_mw_event"] = 0
  
  DF <- DF %>% group_by(zipcode) %>%
    mutate(cumsum_events = cumsum(sal_mw_event))
  
  max_n_events = max(DF$cumsum_events, na.rm = T)
  
  for (event in 1:max_n_events) {
    
    DF[, paste0("mw_event_", event)] = as.numeric(DF$cumsum_events >= event)
  }
  
  return(DF)
}


simulate_housing_values <- function(DF) {
  
  return(DF)
}


main()

