remove(list = ls())

library(tidycensus)
library(tidyverse)

source("../../../lib/R/save_data.R")

# In case the key ceases working see https://www.census.gov/content/dam/Census/library/publications/2020/acs/acs_api_handbook_2020_ch02.pdf
census_api_key("b04b7f3197f8bf4bdc31956fcfb3f28364ccf6cb")

main <- function(){
  outstub <- "../../../drive/base_large/demographics"

  pop_vars <- c("H001001", "H002002", "P001001", "P002002",
                "P003002", "P003003", "P012002")
  tenure_vars <- c("H004004")

  dt <- data.table()
  for (st in state.abb) {
    dt_state <- get_decennial(geography = "block", 
                              variables = c(pop_vars, tenure_vars), 
                              year = 2010, state = st) %>%
                select(-NAME) %>%
                rename(block = GEOID)

    dt_state <- dt_state %>%
      pivot_wider(names_from = variable,
                  values_from = value)

    dt_state <- dt_state %>%
      rename(n_hhlds                 = H001001,
             n_hhlds_urban           = H002002,
             n_hhlds_renter_occupied = H004004,
             population              = P001001,
             urban_population        = P002002,
             n_white                 = P003002,
             n_black                 = P003003,
             n_male                  = P012002)

    dt <- rbindlist(list(dt, dt_state))
  }

  save_data(dt, key = "block",
            filename = file.path(outstub, "census_cb_2010.csv"),
            logfile  = "../output/data_manifest.log")
}

main()
