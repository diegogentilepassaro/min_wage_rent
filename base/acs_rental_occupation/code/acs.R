library(tidycensus)
library(tidyverse)
library(data.table)

source("../../../lib/R/save_data.R")

main <- function(){
  census_api_key("b04b7f3197f8bf4bdc31956fcfb3f28364ccf6cb")
  
  dt <- get_acs(geography = "zcta", 
                variables = c("B25011_001E", "B25011_002E", "B25007_012E"), 
                year = 2019) %>%
    select(-NAME, -moe)
  
  dt <- dt %>%
    pivot_wider(names_from = variable,
                values_from = estimate)
  dt <- dt %>%
    rename(zcta = GEOID,
           total = B25011_001,
           owner_occupied = B25011_002,
           renter_occupied = B25007_012)
  
  save_data(dt, key = "zcta",
            filename = file.path("../output", "acs_rental_occupation.csv"),
            logfile  = "../output/data_manifest.log")
}

main()
