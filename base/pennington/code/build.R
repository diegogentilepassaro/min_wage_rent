remove(list = ls())
source("../../../lib/R/save_data.R")
library(stargazer)
library(data.table)
library(tidyverse)

main <- function() {
  outdir <- "../output/"
  log_file <- "../output/data_file_manifest.log"
  
  data <- fread("../temp/clean_2000_2018/clean_2000_2018.csv") %>%
    mutate(month = as.numeric(substr(date,5,6)))
  
  data_with_sqft <- data %>%
    filter(is.na(sqft) == 0) %>%
    select(post_id, year, month, nhood, city, county,
           price, beds, baths, sqft, room_in_apt)
  
  save_data(data_with_sqft, key = c('post_id'),
            filename = paste0(outdir, 'clean_pennington_bay_area.csv'),
            logfile = log_file)
}

main()
