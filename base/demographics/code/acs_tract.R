remove(list = ls())

library(tidycensus)
library(tidyverse)

source("../../../lib/R/save_data.R")

# In case the key ceases working see https://www.census.gov/content/dam/Census/library/publications/2020/acs/acs_api_handbook_2020_ch02.pdf
census_api_key("b04b7f3197f8bf4bdc31956fcfb3f28364ccf6cb")

main <- function(){
  outstub <- "../../../drive/base_large/demographics"

  demo_vars <- c("B01001_002E", "B25003_001E", "B25003_002E", "B25003_003E", 
                "B02001_001E", "B02001_002E", "B02001_003E")
  inc_vars  <- c("B19019_001E")
  binned_income_hhld_vars <- c("B19001_002E", "B19001_003E", 
                               "B19001_004E", "B19001_005E", "B19001_006E",
                               "B19001_007E", "B19001_008E", "B19001_009E", 
                               "B19001_010E", "B19001_011E", "B19001_012E",
                               "B19001_013E", "B19001_014E", "B19001_015E", 
                               "B19001_016E", "B19001_017E")
  binned_income_worker_vars <- c("B08119_001E", "B08119_002E", "B08119_003E", 
                                 "B08119_004E", "B08119_005E", "B08119_006E",
                                 "B08119_007E", "B08119_008E", "B08119_009E")
  
  dt <- data.table()
  for (st in 1) {
    dt_state <- get_acs(geography = "tract", 
                        variables = c(demo_vars, inc_vars, 
                                      binned_income_hhld_vars, binned_income_worker_vars), 
                        year = 2011, state = st) %>%
      select(-NAME, -moe) %>%
      rename(tract = GEOID)
    
    dt_state <- dt_state %>%
      pivot_wider(names_from = variable,
                  values_from = estimate)
    
    dt_state <- dt_state %>%
      rename(population = B02001_001,
             n_male                  = B01001_002,
             n_white                 = B02001_002,
             n_black                 = B02001_003,
             n_hhlds                 = B25003_001,
             med_hhld_inc            = B19019_001,
             n_hhlds_owner_occupied  = B25003_002,
             n_hhlds_renter_occupied = B25003_003,
             n_hhlds_less_10k_inc    = B19001_002,
             n_hhlds_10to15k_inc     =  B19001_003, 
             n_hhlds_15to20k_inc     = B19001_004, 
             n_hhlds_20to25k_inc     = B19001_005, 
             n_hhlds_25to30k_inc     = B19001_006, 
             n_hhlds_30to35k_inc     = B19001_007,
             n_hhlds_35to40k_inc     = B19001_008, 
             n_hhlds_40to45k_inc     = B19001_009, 
             n_hhlds_45to50k_inc     = B19001_010, 
             n_hhlds_50to60k_inc     = B19001_011, 
             n_hhlds_60to75k_inc     = B19001_012, 
             n_hhlds_75to100k_inc    = B19001_013,
             n_hhlds_100to125k_inc   = B19001_014, 
             n_hhlds_125to150k_inc   = B19001_015, 
             n_hhlds_150to200k_inc   = B19001_016, 
             n_hhlds_more_200k_inc   = B19001_017,
             n_workers               = B08119_001,
             n_workers_less_10k_inc  = B08119_002,
             n_workers_10to15k_inc   = B08119_003, 
             n_workers_15to25k_inc   = B08119_004, 
             n_workers_25to35k_inc   = B08119_005, 
             n_workers_35to50k_inc   = B08119_006, 
             n_workers_50to65k_inc   = B08119_007,
             n_workers_65to75k_inc   = B08119_008, 
             n_workers_more_75k_inc  = B08119_009) %>%
      select(tract, population, 
             n_male, n_white, n_black,
             n_hhlds, med_hhld_inc, n_hhlds_owner_occupied, n_hhlds_renter_occupied,
             n_hhlds_less_10k_inc, n_hhlds_10to15k_inc, n_hhlds_15to20k_inc, 
             n_hhlds_20to25k_inc,  n_hhlds_25to30k_inc, n_hhlds_30to35k_inc,
             n_hhlds_35to40k_inc, n_hhlds_40to45k_inc, n_hhlds_45to50k_inc, 
             n_hhlds_50to60k_inc, n_hhlds_60to75k_inc, n_hhlds_75to100k_inc,
             n_hhlds_100to125k_inc, n_hhlds_125to150k_inc, 
             n_hhlds_150to200k_inc, n_hhlds_more_200k_inc,
             n_workers, n_workers_less_10k_inc, n_workers_10to15k_inc,
             n_workers_15to25k_inc, n_workers_25to35k_inc, n_workers_35to50k_inc,
             n_workers_50to65k_inc, n_workers_65to75k_inc, n_workers_more_75k_inc)
    
    dt <- rbindlist(list(dt, dt_state))
  }
  
  save_data(dt, key = "tract",
            filename = file.path(outstub, "acs_tract_2011.csv"),
            logfile  = "../output/data_manifest.log")
}

main()
