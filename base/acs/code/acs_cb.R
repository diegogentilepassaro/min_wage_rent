remove(list = ls())

library(tidycensus)
library(tidyverse)

source("../../../lib/R/save_data.R")

# In case the key ceases working see https://www.census.gov/content/dam/Census/library/publications/2020/acs/acs_api_handbook_2020_ch02.pdf
census_api_key("b04b7f3197f8bf4bdc31956fcfb3f28364ccf6cb")

main <- function(){
  pop_vars <- c("H001001", "H002001", "H002002", 
                "H006002", "H006003")
  tenure_vars <- c("H004004")
  vacancy_vars <- c("H005002", "H005003", "H005004", 
                    "H005005", "H005006", "H005007",
                    "H005008")

  dt <- data.table()
  for (st in state.abb) {
    dt_state <- get_decennial(geography = "block", 
                              variables = c(pop_vars, tenure_vars, vacancy_vars), 
                              year = 2010, state = st) %>%
                select(-NAME) %>%
                rename(block = GEOID)

    dt_state <- dt_state %>%
      pivot_wider(names_from = variable,
                  values_from = value)

    dt_state <- dt_state %>%
      rename(total_households = H001001,
             population = H002001,
             urban_population = H002002,
             white_hh = H006002,
             black_hh = H006003,
             renter_occupied = H004004,
             for_rent = H005002,
             rented_not_occ = H005003,
             for_Sale = H005004,
             sold_not_occ = H005005,
             seasonal_use = H005006,
             for_migrant_wkrs = H005007,
             other_vacant = H005008)

    dt <- rbindlist(list(dt, dt_state))
  }

  save_data(dt, key = "block",
            filename = "../output/census_cb_2010.csv",
            logfile  = "../output/data_manifest.log")
}

main()
