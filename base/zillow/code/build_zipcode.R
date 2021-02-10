remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")
source("fix_varnames.R")

load_packages(c('stringr', 'data.table'))

main <- function() {
   
   datadir  <- "../../../drive/raw_data/zillow/Zip_122019"
   outdir   <- "../../../drive/base_large/zillow"
   xwalkdir <- "../../geo_master/output"
   log_file <- "../output/data_file_manifest.log"
   
   raw_filenames <- list.files(datadir, pattern = "*.csv", full.names = T)
   raw_filenames <- raw_filenames[!str_detect(raw_filenames, "_Summary.csv")]
   
   l <- lapply(raw_filenames, clean_rawdata) # Recursively rename vars and save files in ../temp
   
   dts <- reshape_zillow("../temp")
   
   dt <- build_frame(dts)
   
   for (name in names(dts)) {
      dt <- merge(dt, dts[[name]], by = c('zipcode', 'date'), all.x = TRUE)
   }

   dt <- add_geographies(dt, xwalkdir)
   
   save_data(dt, key = c('zipcode', 'date'), 
             filename = file.path(outdir, 'zillow_zipcode_clean.csv'),
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

add_geographies <- function(dt, xwalkdir) {

   geo_master <- fread(file.path(xwalkdir, "zcta_county_place_usps_master_xwalk.csv"),
                       colClasses = 'character')
   target_geovars <- c("zipcode", "countyfips", "place_code", "cbsa10", "statefips")
   
   geo_master <- geo_master[, ..target_geovars][, first(.SD), by = "zipcode"]
   geo_master[, zipcode := as.integer(zipcode)]
   
   dt <- left_join(dt, geo_master, by = "zipcode")

   return(dt)
}

# Execute
main()
