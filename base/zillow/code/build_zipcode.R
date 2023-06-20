remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")
source("fix_varnames.R")

load_packages(c('stringr', 'data.table'))

main <- function() {
   
   datadir      <- "../../../drive/raw_data/zillow/Zip_122019"
   datadir_2023 <- "../../../drive/raw_data/zillow_2023/orig"
   outdir       <- "../../../drive/base_large/zillow"
   log_file     <- "../output/data_file_manifest.log"
   
   raw_filenames <- list.files(datadir, pattern = "*.csv", full.names = T)
   raw_filenames <- raw_filenames[!str_detect(raw_filenames, "_Summary.csv")]

   l <- lapply(raw_filenames, clean_rawdata) # Recursively rename vars and save files in ../temp

   dts <- reshape_zillow("../temp")
   
   dt <- build_frame(dts)
   
   for (name in names(dts)) {
      dt <- merge(dt, dts[[name]], by = c('zipcode', 'date'), all.x = TRUE)
   }

   dt[, c('year', 'month') :=  .(as.numeric(substr(date, 1, 4)),
                                 as.numeric(substr(date, 6, 7)))]
   dt[, date := NULL]
   
   dt <- add_data_2023(dt, datadir_2023)
   
   dt[, zipcode := str_pad(zipcode, 5, pad = 0)]
   
   save_data(dt, key = c('zipcode', 'year', 'month'), 
             filename = file.path(outdir, 'zillow_zipcode_clean.csv'),
             logfile = log_file)
   save_data(dt, key = c('zipcode', 'year', 'month'), 
             filename = file.path(outdir, 'zillow_zipcode_clean.dta'),
             logfile = log_file)
}

clean_rawdata <- function(x) {
   dt <- fread(x, stringsAsFactors = F)
   
   all_names <- colnames(dt)
   date_names <- all_names[str_detect(all_names, "[0-9]")]
   vars_to_keep <- c("RegionName", date_names)
   
   dt <- dt[, ..vars_to_keep]
   setnames(dt, old = "RegionName", new = "zipcode")
   
   save_data(dt, key = "zipcode", 
             filename = file.path("../temp", basename(x)),
             nolog = T)
}

reshape_zillow <- function(infolder) {
   
   files <- list.files(infolder, pattern = "*.csv")
   
   value_names <- str_replace_all(files, "Zip_|.csv", "")
   value_names <- fix_varnames_zipcode(value_names)
   
   dts <- mapply(reshape_single_file,
                 filename = files, valname = value_names,
                 MoreArgs = list(infolder), SIMPLIFY = F)
   
   return(dts)
}

reshape_single_file <- function(filename, valname, infolder) {
   dt <- fread(file.path(infolder, filename), stringsAsFactors = F)
   
   dt <- melt(dt, id.vars = 'zipcode',
              variable.name = 'date', value.name = valname)
   
   return(dt)
}

build_frame <- function(dts){
   
   zipcodes <- unique(unlist(lapply(dts, function(dt) unique(dt$zipcode))))
   dates    <- unique(unlist(lapply(dts, function(dt) unique(dt$date))))
   
   return(data.table(
      "zipcode" = rep(zipcodes, each = length(dates)),
      "date"    = rep(dates, times = length(zipcodes))
   ))
}

add_data_2023 <- function(dt, datadir_2023) {
  
  zori <- fread(file.path(datadir_2023, "Zip_zori_sm_month.csv"))
  
  date_vars <- names(zori)[grepl("20", names(zori))]
  keep_vars <- c("RegionID", date_vars)
  
  zori <- zori[, ..keep_vars]
  setnames(zori, old = "RegionID", new = "zipcode")
  
  zori <- melt(zori,
               id.vars = "zipcode",
               measure.vars = date_vars,
               variable.name = "date",
               value.name = "zori_2023",
               variable.factor = F)
  
  zori[, year  := as.numeric(substr(date, 1, 4))]
  zori[, month := as.numeric(substr(date, 6, 7))]
  zori[, date := NULL]
  
  zori <- zori[year <= 2020]   # Drop years after 2020
  
  dt <- merge(dt, zori, 
              all = T,  # Keep all matches
              by = c("zipcode", "year", "month"))
  
  return(dt)
}

# Execute
main()
