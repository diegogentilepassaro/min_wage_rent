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
            logfile  = sprintf("%s/data_file_manifest.log", logfolder))
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
  hs_week    = 40
  week_month = 4.35
  mw_earners = 2
  
  sd_shock    = 75
  theta       = 0.05 # passthrough
  theta_level = 30
  
  DF <- prepare_DF(DF, var)
  
  size_df            <- dim(DF)[1]
  max_n_events       <- max(DF$cumsum_events, na.rm = T)
  numeric_yearmonths <- 596:715

  # Define objects
  mean_r = sapply(DF[, c(var)], mean, na.rm = T)
  sd_r   = sapply(DF[, c(var)], sd,  na.rm = T)
  min_r  = ceiling(sapply(DF[, c(var)], min, na.rm = T))
  max_r  = ceiling(sapply(DF[, c(var)], max, na.rm = T))
  
  zipcodes = unique(DF[, c('zipcode')])
  states   = unique(DF[, c('statefips')])
  year_months = unique(DF[, c('year_month')])
  
  n_states = dim(states)[1]
  
  # iid shock
  DF$shock <- rnorm(size_df, mean = 0, sd = sd_shock)
  
  # Zipcode effect
  zipcodes_avgs = aggregate(DF[, var], by = list(DF$zipcode), FUN = quantile, probs = c(0.2), na.rm = T)
  names(zipcodes_avgs) <- c("zipcode", "zipcode_effect")
  
  zipcodes <- merge(zipcodes, zipcodes_avgs, by = 'zipcode')
  DF <- merge(DF, zipcodes, by = 'zipcode')
  
  # Year-month effect
  period_avgs = aggregate(DF[, var], by = list(DF$year_month), FUN = mean, na.rm = T)
  names(period_avgs) <- c("year_month", "timeperiod_effect")
  
  period_avgs$timeperiod_effect = period_avgs$timeperiod_effect - mean(period_avgs$timeperiod_effect, na.rm = T) # Demean
  
  year_months <- merge(year_months, period_avgs, by = 'year_month')
  DF <- merge(DF, year_months, by = 'year_month')
  
  # State-specific Year-month
  states$state_effect = runif(n_states, min = 0, max = 200)
  
  st_panel = cbind(rep(states$statefips, times = 1, each = 120),
                   rep(states$state_effect, times = 1, each = 120),
                   rep(numeric_yearmonths, times = n_states))
  
  colnames(st_panel) = c("statefips", "state_trend", "year_month")
  st_panel <- as.data.frame(st_panel)
  
  for (state in unique(st_panel$statefips)) {      # Generate time series for each state
    rate = runif(1, min = 0.001, max = 0.007)
    
    for (period in numeric_yearmonths) {
      if (period == 596) next                      # Skip first
      
      prev_period = st_panel[(st_panel$statefips == state) & 
                             (st_panel$year_month == period), "state_trend"]
      
      st_panel[(st_panel$statefips == state) & 
               (st_panel$year_month == period), "state_trend"] = (1 + rate)*prev_period
    }
  }
  
  DF <- merge(DF, st_panel[, c("statefips", "year_month", "state_trend")], 
              by = c("statefips", "year_month"))
  
  # Min wage effect  
  DF$mw_effect       <- theta*DF$dactual_mw_1*hs_week*week_month*mw_earners
  DF$mw_effect_level <- ifelse(DF$dactual_mw_1 == 1, theta_level, 0)
  
  for (event in 2:max_n_events) {
    DF$this_effect       <- theta*DF[, paste0("dactual_mw_", event)]*hs_week*week_month*mw_earners
    DF$this_effect_level <- ifelse(DF[, paste0("dactual_mw_", event)] == 1, theta_level, 0)
    
    DF$mw_effect       <- DF$mw_effect + DF$this_effect
    DF$mw_effect_level <- DF$mw_effect_level + DF$this_effect_level
  }
  
  
  # SIMULATE
  DF$rent1 <- DF$zipcode_effect + DF$timeperiod_effect + DF$shock
  DF$rent1 <- ifelse(DF$rent1 < min_r, min_r, ifelse(DF$rent1 > max_r, max_r, DF$rent1))
  
  DF$rent2 <- DF$zipcode_effect + DF$timeperiod_effect + DF$mw_effect + DF$shock
  DF$rent2 <- ifelse(DF$rent2 < min_r, min_r, ifelse(DF$rent2 > max_r, max_r, DF$rent2))
  
  DF$rent3 <- DF$zipcode_effect + DF$timeperiod_effect + DF$mw_effect_level + DF$shock
  DF$rent3 <- ifelse(DF$rent3 < min_r, min_r, ifelse(DF$rent3 > max_r, max_r, DF$rent3))
  
  DF$rent4 <- DF$zipcode_effect + DF$timeperiod_effect + DF$state_trend + DF$shock
  DF$rent4 <- ifelse(DF$rent4 < min_r, min_r, ifelse(DF$rent4 > max_r, max_r, DF$rent4))
  
  DF$rent5 <- DF$zipcode_effect + DF$timeperiod_effect + DF$state_trend + DF$mw_effect + DF$shock
  DF$rent5 <- ifelse(DF$rent5 < min_r, min_r, ifelse(DF$rent5 > max_r, max_r, DF$rent5))
  
  DF$rent6 <- DF$zipcode_effect + DF$timeperiod_effect + DF$state_trend + DF$mw_effect_level + DF$shock
  DF$rent6 <- ifelse(DF$rent6 < min_r, min_r, ifelse(DF$rent6 > max_r, max_r, DF$rent6))

  DF <- DF %>% select(-c(this_effect, this_effect_level, this_change))
  
  return(DF)
}


prepare_DF <- function(DF, var) {
  
  DF <- DF %>% group_by(zipcode) %>% filter(any(!is.na(eval(parse(text=var)))))
  DF <- DF[(DF$year_month >= 596) & (DF$year_month <= 715),]
  
  DF[is.na(DF$sal_mw_event), "sal_mw_event"] = 0
  
  DF <- DF %>% group_by(zipcode) %>%
    mutate(cumsum_events = cumsum(sal_mw_event))
  
  max_n_events = max(DF$cumsum_events, na.rm = T)
  
  for (event in 1:max_n_events) {
    
    DF[, paste0("mw_event_", event)] = as.numeric(DF$cumsum_events >= event)
    
    DF <- DF %>% group_by(zipcode) %>%
      mutate(this_change = ifelse(cumsum_events == event, max(dactual_mw), 0))
    DF <- DF %>% group_by(zipcode) %>%
      mutate(this_change = max(this_change))
    
    DF[, paste0("dactual_mw_", event)] = DF[, paste0("mw_event_", event)]*DF$this_change
  }
  
  return(DF)
}


simulate_housing_values <- function(DF, rent_var) {

  ### UNDER CONSTRUCTION
  
  return(DF)
}


main()

