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
   
   dts <- lapply(raw_filenames, rename_geovars)
   
   dts <- reshape_zillow(dts, raw_filenames)
   
   dt <- Reduce(function(...) merge(..., all = TRUE), dts)
   
   dt[, county := str_replace_all(county, " County", "")]
   
   save_data(dt, key = c('countyfips', 'statefips', 'date'), 
             filename = file.path(outdir, 'zillow_county_clean.csv'),
             logfile = log_file)
}

rename_geovars <- function(x) {
   dt <- fread(x, stringsAsFactors = F)[, SizeRank := NULL]
   
   old_geo_names <- colnames(dt)[!str_detect(colnames(dt), "[0-9]")]
   new_geo_names <- c("county", "stateabb", "msa", "statefips", "countyfips")
   
   setnames(dt, old = old_geo_names, new = new_geo_names)
   
   n_unique <- dim(unique(dt[, ..new_geo_names]))[1]
   stopifnot(n_unique == dim(dt)[1])  # Check if key
   
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
   
   idvars <- names(dt)[!str_detect(names(dt), "[0-9]")]
   
   dt <- melt(dt, id.vars = idvars,
              variable.name = 'date', value.name = valname)
   
   return(dt)
}

# Execute
main()
