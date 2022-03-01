remove(list = ls())

library(tidycensus)
library(tidyverse)

source("../../../lib/R/save_data.R")

# In case the key ceases working see https://www.census.gov/content/dam/Census/library/publications/2020/acs/acs_api_handbook_2020_ch02.pdf
census_api_key("b04b7f3197f8bf4bdc31956fcfb3f28364ccf6cb")

main <- function(){
  pop_vars <- c("B00001_001E", "B00002_001E", "B25003_002E", 
                "B25003_003E", "B01001B_001E", "B01001I_001E")
  income_vars <- c("B19313_001E","B19051_001E", "B19051_002E", "B19051_003E", 
                   "B19052_001E", "B19052_002E", "B19052_003E")
  binned_income_vars <- c("B19001_002E", "B19001_003E", 
                          "B19001_004E", "B19001_005E", "B19001_006E",
                          "B19001_007E", "B19001_008E", "B19001_009E", 
                          "B19001_010E", "B19001_011E", "B19001_012E",
                          "B19001_013E", "B19001_014E", "B19001_015E", 
                          "B19001_016E", "B19001_017E")

  dt <- data.table()
  for (st in state.abb) {
    dt_state <- get_acs(geography = "block group", 
                variables = c(pop_vars, income_vars, binned_income_vars), 
                year = 2013, state = st) %>%
        select(-NAME, -moe) %>%
        rename(block_group = GEOID)

    dt_state <- dt_state %>%
      pivot_wider(names_from = variable,
                  values_from = estimate)

    dt_state <- dt_state %>%
      rename(population = B00001_001,
             total_households = B00002_001,
             owner_occupied = B25003_002,
             renter_occupied = B25003_003,
             black = B01001B_001,
             hispanic = B01001I_001,
             agg_income_hhld = B19313_001,
             total_earnings_hhld = B19051_001,
             total_earnings_hhld_w_earnings = B19051_002,
             total_earnings_hhld_no_earnings = B19051_003,
             total_wage_income = B19052_001,
             total_wage_income_w_wage = B19052_002,
             total_wage_income_no_wage = B19052_003,
             n_hhlds_less_10k_inc = B19001_002,
             n_hhlds_10to15k_inc =  B19001_003, 
             n_hhlds_15to20k_inc = B19001_004, 
             n_hhlds_20to25k_inc = B19001_005, 
             n_hhlds_25to30k_inc = B19001_006, 
             n_hhlds_30to35k_inc = B19001_007,
             n_hhlds_35to40k_inc = B19001_008, 
             n_hhlds_40to45k_inc = B19001_009, 
             n_hhlds_45to50k_inc = B19001_010, 
             n_hhlds_50to60k_inc = B19001_011, 
             n_hhlds_60to75k_inc = B19001_012, 
             n_hhlds_75to100k_inc = B19001_013,
             n_hhlds_100to125k_inc = B19001_014, 
             n_hhlds_125to150k_inc = B19001_015, 
             n_hhlds_150to200k_inc = B19001_016, 
             n_hhlds_more_200k_inc = B19001_017)

    dt <- rbindlist(list(dt, dt_state))
  }

  save_data(dt, key = "block_group",
            filename = "../output/acs_cbg_2013.csv",
            logfile  = "../output/data_manifest.log")
}

main()
