remove(list = ls())

library(data.table)
library(stringr)
library(magrittr)

source("../../../lib/R/save_data.R")

main <- function () {
  vars <-
    c(
      "total_units",
      "pct_occupied",
      "number_reported",
      "pct_reported",
      "months_since_report",
      "people_per_unit",
      "people_total",
      "rent_per_month",
      "spending_per_month",
      "hh_income",
      "person_income",
      "pct_wage_major",
      "pct_lt50_median",
      "pct_2adults",
      "pct_1adult",
      "pct_minority",
      "pct_black_nonhsp",
      "pct_hispanic",
      "pct_bed1",
      "pct_bed2",
      "pct_bed3",
      "tpoverty",
      "year",
      "zipcode",
      "census_tract",
      "city",
      "program_label"
    )
  
  geographies <- c("zipcode", "census_tract", "city")
  
  data_path <- '../../../drive/raw_data/hud_housing_assistance'
  
  drive_path <- '../../../drive/base_large/hud_housing_assistance/'
  
  for (gg in geographies) {
    files_path <- file.path(data_path, gg)
    files_names <-
      list.files(files_path, pattern = ".xlsx", full.names = T)
    
    data <- rbindlist(lapply(files_names, function (x) {
      year <- str_remove(x, ".*/") %>%
        str_remove("PLACE_") %>%
        str_remove(".xlsx") %>%
        str_remove("_2010geography.*") %>%
        str_remove("Zipcode_") %>%
        str_remove("TRACT_AK_MN_") %>%
        str_remove("TRACT_MO_WY_") %>%
        as.numeric()
      
      data <- as.data.table(readxl::read_xlsx(x))[, year := year]
      
      if (gg == "city") {
        data <- data[state != "PR"]
        setnames(data, "entities", gg)
      }
      else {
        setnames(data, "code", gg)
      }
      
      vars_av <- intersect(names(data), vars)
      
      return(data[, ..vars_av])
    }),
    fill = TRUE)
    
    # Remove duplicated observations
    
    if (gg == "census_tract") {
      data <- data[!(
        program_label == "Summary of All HUD Programs" &
          census_tract == "29186960200" &
          year == 2015 &
          total_units == 9
      ) &
        !(
          program_label == "Project Based Section 8" &
            census_tract == "29186960200" &
            year == 2015 &
            total_units == 9
        )]
    }
    
    save_data(
      data,
      key = c(gg, "program_label", "year"),
      filename = file.path(drive_path, paste0(gg, ".csv")),
      logfile = file.path("../output", paste0(gg, ".log"))
    )
    save_data(
      data,
      key = c(gg, "program_label", "year"),
      filename = file.path(drive_path, paste0(gg, ".dta")),
      nolog = TRUE
    )
  }
}

main()