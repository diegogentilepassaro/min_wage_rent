remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")

load_packages(c('tidyverse', 'data.table', 'tidycensus', 'bit64', 'readxl'))
options(scipen=999)

main <- function() {
  data_version <- '0055'
  
  datadir  <- paste0("../../../drive/raw_data/census/tract/nhgis", data_version, "_csv/")
  xwalkdir <- "../../geo_master/output/" 
  outdir   <- "../../../drive/base_large/demographics/"
  tempdir  <- "../temp"
  log_file <- "../output/data_file_manifest.log"
  
  xwalk <- fread(paste0(xwalkdir, "tract_zip_master.csv"),
                 colClasses = c("tract_fips" = "character", "zipcode" = "character"))
  
  table_list <- list.files(datadir, 
                           pattern = "*.csv", 
                           full.names = T)
  
  table_clean <- lapply(table_list, format_tables, xwalk = xwalk)
  
  table_clean <- rbindlist(table_clean, use.names = TRUE)
  setorderv(table_clean, cols = c('zipcode', 'year'))
  table_clean <- table_clean[!is.na(year)]

  save_data(table_clean, 
            filename = paste0(outdir, 'acs_population_zipyear.csv'), 
            logfile = log_file, 
            key = c('zipcode', 'year'))
  save_data(table_clean, 
            filename = paste0(outdir, 'acs_population_zipyear.dta'), 
            logfile = log_file, 
            key = c('zipcode', 'year'))
}

format_tables <- function(x, xwalk) {
  data <- fread(x, colClasses = c("STATEA"  = "character",
                                  "COUNTYA" = "character",
                                  "TRACTA"  = "character"))
  
  data[, countyfips := paste0(STATEA, COUNTYA)]
  data[, tract_fips := paste0(countyfips, TRACTA)]
  setnames(data, old = c("CBSAA", "YEAR"), 
                 new = c("cbsa", "year"))
  data[, year := as.numeric(substring(year, nchar(year)-4 + 1))]
  
  #The population variable has a different name in each ACS
  varname_list <- c('JMAE001', 'MNTE001', 'QSPE001', 
                    'UEPE001', 'ABA1E001', 'ADKWE001', 
                    'AF2LE001', 'AHY1E001', 'AJWME001', 'ALUBE001')
  target_pop <- intersect(varname_list, names(data))
  setnames(data, old = target_pop, new = 'acs_pop')
  target_vars <- c('tract_fips', 'countyfips', 'year', 'acs_pop')
  
  data <- data[, ..target_vars]  
  
  data <- crosswalk_table_tractzip(data, xwalk = xwalk)

  return(data)
}

crosswalk_table_tractzip <- function(data, xwalk) {
  data <- data[xwalk, on = 'tract_fips']

  data <- data[, .(acs_pop = sum(acs_pop*res_ratio, na.rm = T)),
               by = c('zipcode', 'year')]
  
  return(data)
}

main()
