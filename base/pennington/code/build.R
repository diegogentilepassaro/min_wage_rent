remove(list = ls())
source("../../../lib/R/save_data.R")
library(stargazer)
library(dplyr)
library(stringr)

main <- function() {
  outdir <- "../../../drive/base_large/pennington/"
  log_file <- "../output/data_file_manifest.log"
  
  data <- data.table::fread("../temp/clean_2000_2018/clean_2000_2018.csv") %>%
    mutate(month = as.numeric(substr(date,5,6)))
  
  data_with_sqft <- data %>%
    filter(is.na(sqft) == 0) %>%
    select(year, month, nhood, city, county,
           price, beds, baths, sqft, room_in_apt) %>%
    mutate(post_id = row_number(),
           beds = as.integer(str_remove(beds, "\\s+")))
  
  save_data(data_with_sqft, key = c('post_id'),
            filename = paste0(outdir, 'clean_pennington_bay_area.csv'),
            logfile = log_file)
}

main()
