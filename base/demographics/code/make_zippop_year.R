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
                 colClasses = c('numeric', 'numeric', 'numeric'))
  
  table_list <- list.files(datadir, 
                           pattern = "*.csv")
  
  table_list <- str_remove_all(table_list, paste0("nhgis", data_version, "_"))
  
  table_clean <- lapply(table_list, format_tables, datadir = datadir, data_version = data_version, xwalk = xwalk)
  
  table_clean <- rbindlist(table_clean, use.names = TRUE)
  setorderv(table_clean, cols = c('zipcode', 'year'))
  
  table_clean <- table_clean[!is.na(year)]
  table_clean[, c('from', 'to') := list(paste0(year, '-01-01'), paste0(year, '-12-31'))]
  table_clean[, c('from', 'to') := list(as.Date(from), as.Date(to))]
  
  table_clean <- table_clean[, list(zipcode, acs_pop, year_month = seq(from, to, by = "month")), 
                               by = 1:nrow(table_clean)][
                                 , nrow:= NULL]
  
  save_data(table_clean, 
            filename = paste0(outdir, 'acs_population_zipmonth.csv'), 
            logfile = log_file, 
            key = c('zipcode', 'year_month'))
  save_data(table_clean, 
            filename = paste0(outdir, 'acs_population_zipmonth.dta'), 
            logfile = log_file, 
            key = c('zipcode', 'year_month'))
}

format_tables <- function(x, datadir, data_version, xwalk) {
  data <- fread(paste0(datadir, "nhgis", data_version, "_", x))
  
  make_geo <-  function(y) {
    if (class(y)[1] != "data.table") y <- setDT(y)
    
    y[, c('tract_fips', 'county_fips') := list(
      as.numeric(paste0(
        str_pad(STATEA, 2, pad = "0"),
        str_pad(COUNTYA, 3, pad = "0"),
        str_pad(TRACTA, 6, pad = "0"))),
      as.numeric(paste0(str_pad(STATEA, 2, pad = "0"),
                        str_pad(COUNTYA, 3, pad = "0"))))]
    setnames(y, old = c("CBSAA", "YEAR"), new = c("cbsa", "year"))
    
    return(y)
  }
  data <- make_geo(data)
  
  data[, year := as.numeric(substring(year, nchar(year)-4 +1))]
  
  #The population variable has a different name in each ACS
  varname_list <- c('JMAE001', 'MNTE001', 'QSPE001', 'UEPE001', 'ABA1E001', 'ADKWE001', 'AF2LE001', 'AHY1E001', 'AJWME001', 'ALUBE001')
  target_pop <- intersect(varname_list, names(data))
  setnames(data, old = target_pop, new = 'acs_pop')
  target_vars <- c('tract_fips', 'county_fips', 'year', 'acs_pop')
  
  data <- data[, ..target_vars]  
  
  data <- crosswalk_table_tractzip(data, xwalk = xwalk)

  return(data)
}

crosswalk_table_tractzip <- function(data, xwalk) {
 
  data <- data[xwalk, on = 'tract_fips']

  data <- data[, lapply(.SD, function(x, w) sum(x*w, na.rm = T), w=res_ratio),
                                        by = c('zipcode', 'year'),
                                        .SDcols = 'acs_pop']
  
  return(data)
}

main()
