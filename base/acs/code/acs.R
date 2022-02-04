library(tidycensus)
library(tidyverse)
library(data.table)

source("../../../lib/R/save_data.R")

main <- function(){
  census_api_key("b04b7f3197f8bf4bdc31956fcfb3f28364ccf6cb")
  
  for (yyyy in c(2011, 2015, 2019)) {
    dt <- get_acs(geography = "zcta", 
                  variables = c("B01003_001E",
                                "B25011_001E", "B25011_002E", 
                                "B25007_012E", "B01001B_001E",
                                "B01001I_001E", "B08202_001E",
                                "B08202_002E", "B08202_003E",
                                "B08202_004E", "B08202_005E",
                                "B19301_001E", "B19313_001E",
                                "B19051_001E", "B19051_002E",
                                "B19051_003E", "B19052_001E", 
                                "B19052_002E", "B19052_003E"), 
                  year = yyyy) %>%
      select(-NAME, -moe)
    
    dt <- dt %>%
      pivot_wider(names_from = variable,
                  values_from = estimate)
    dt <- dt %>%
      rename(zcta = GEOID,
             population = B01003_001,
             total_households = B25011_001,
             owner_occupied = B25011_002,
             renter_occupied = B25007_012,
             black = B01001B_001,
             hispanic = B01001I_001,
             hhld_size_total = B08202_001,
             hhld_size_no_wrkrs = B08202_002,
             hhld_size_1_wrkr = B08202_003,
             hhld_size_2_wrkr = B08202_004,
             hhld_size_3plus_wrkr = B08202_005,
             income_per_capita = B19301_001,
             agg_income_hhld = B19313_001,
             total_earnings_hhld = B19051_001,
             total_earnings_hhld_w_earnings = B19051_002,
             total_earnings_hhld_no_earnings = B19051_003,
             total_wage_income = B19052_001,
             total_wage_income_w_wage = B19052_002,
             total_wage_income_no_wage = B19052_003)
    
    save_data(dt, key = "zcta",
              filename = file.path("../output", paste0("acs_", yyyy, ".csv")),
              logfile  = "../output/data_manifest.log")
  }
}

main()
