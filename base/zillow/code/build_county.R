remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")
source("fix_varnames.R")

load_packages(c('stringr', 'data.table'))

main <- function() {
   
   datadir  <- "../../../drive/raw_data/zillow/County_122019"
   outdir   <- "../../../drive/base_large/zillow"
   log_file <- "../output/data_file_manifest.log"
   
   raw_filenames <- list.files(datadir, pattern = "*.csv", full.names = T)
   
   dts <- lapply(raw_filenames, load_and_clean)
   
   dts <- reshape_zillow(dts, raw_filenames)
   
   dt <- build_frame(dts)
   
   for (i in 1:length(dts)) {
      dt <- merge(dt, dts[[i]], by = c('countyfips', 'date'), all.x = TRUE)
   }

   save_data(dt, key = c('countyfips', 'date'), 
             filename = file.path(outdir, 'zillow_county_clean.csv'),
             logfile = log_file)
}

load_and_clean <- function(x) {
   dt <- fread(x, colClasses = )[, SizeRank := NULL]
   
   all_names <- colnames(dt)
   date_names <- all_names[str_detect(all_names, "[0-9]")]
   vars_to_keep <- c("StateCodeFIPS", "MunicipalCodeFIPS", date_names)
   
   dt <- dt[, ..vars_to_keep]
   dt[, countyfips := paste0(str_pad(StateCodeFIPS, 2, "left", pad = 0),
                             str_pad(MunicipalCodeFIPS, 3, "left", pad = 0))]
   dt[, c("StateCodeFIPS", "MunicipalCodeFIPS") := NULL]
   
   return(dt)
}

reshape_zillow <- function(dts, filenames) {
   
   value_names <- str_replace_all(basename(filenames), "County_|.csv", "")
   value_names <- fix_varnames_county(value_names)
   
   dt_zillow <- mapply(reshape_single_file,
                       dt = dts, valname = value_names, SIMPLIFY = F)
   
   return(dt_zillow)
}

reshape_single_file <- function(dt, valname) {
   
   dt <- melt(dt, id.vars = 'countyfips',
              variable.name = 'date', value.name = valname)
   
   return(dt)
}

build_frame <- function(dts){
   
   counties <- unique(unlist(lapply(dts, function(dt) unique(dt$countyfips))))
   dates    <- unique(unlist(lapply(dts, function(dt) unique(dt$date))))
   
   return(data.table(
      "countyfips" = rep(counties, each = length(dates)),
      "date"       = rep(dates, times = length(counties))
   ))
}

# Execute
main()
