library(haven)
library(dplyr)

main <- function() {
  infile <- "./drive/derived_large/output/zipcode_yearmonth_panel_all.dta"
  
  DF <- read_dta(infile)
  
  DF <- DF[, c("zipcode", "year_month", "zcta", "placetype", "countyfips", "statefips", "msa",
               "fed_mw", "state_mw", "county_mw", "local_mw", "actual_mw", "dactual_mw",
               "mw_event", "sal_mw_event", "mw_event025", "mw_event075",
               "medlistingprice_sfcc", "medlistingprice_sfcc",
               "pct_zip_houses_incounty", "pct_zip_pop_incounty", "pop10_zip_county")]
  
  
}


simulate_rents <- function() {
  
  
}


simulate_housing_values <- function() {
  
  
}


main

