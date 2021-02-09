remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")
source("fix_varnames.R")

load_packages(c('stringr', 'data.table'))

main <- function() {
   
   datadir  <- "../../../drive/raw_data/zillow/Zip_122019"
   outdir   <- "../../../drive/base_large/zillow"
   log_file <- "../output/data_file_manifest.log"
   
   raw_filenames <- list.files(datadir, pattern = "*.csv", full.names = T)
   raw_filenames <- raw_filenames[!str_detect(raw_filenames, "_Summary.csv")]
   
   lapply(raw_filenames, rename_zillow) # Recursively rename and saves files in ../temp
   
   dts_list <- reshape_zillow("../temp")
   
   dt <- merge_zillow(l = dts_list, key = c('zipcode', 'date'))
   
   save_data(dt, key = c('zipcode', 'date'), 
             filename = file.path(outdir, 'zillow_zipcode_clean.csv'),
             logfile = log_file)
}

rename_zillow <- function(x) {
   df <- fread(x, stringsAsFactors = F)
   
   if (any(c("DataTypeDescription", "SizeRank", "RegionType") %in% names(df))) {
      df[, c("DataTypeDescription", "SizeRank", "RegionType") := NULL]
   }
   
   geo_names <- colnames(df)
   geo_names <- geo_names[!str_detect(geo_names, "[0-9]")]
   
   geo_names_1 <- c("RegionName", "City", "CountyName", "Metro", "StateFullName")
   geo_names_2 <- c("RegionID", "RegionName", "City", "County", "State", "Metro")
   geo_names_3 <- c("RegionName", "City", "State", "Metro", "CountyName")
   geo_names_4 <- c("RegionID", "RegionName", "City", "State", "Metro", "CountyName")
   geo_names_5 <- c("RegionID", "RegionName", "City", "County", "State", "Metro")
   geo_names_6 <- c("RegionID", "RegionName", "StateName")
   
   if (identical(geo_names, geo_names_1)) {
      newgeonames <- c("zipcode", "city", "county", "msa", "statename")
      setnames(df, old = geo_names, new = newgeonames)
      
   } else if (identical(geo_names, geo_names_2)) {
      newgeonames <- c("old_id", "zipcode", "city", "county", "stateabb", "msa")
      setnames(df, old = geo_names, new = newgeonames)
      
   } else if (identical(geo_names, geo_names_3)) {
      newgeonames <- c("zipcode", "city", "stateabb", "msa", "county")
      setnames(df, old = geo_names, new = newgeonames)

   } else if (identical(geo_names, geo_names_4)) {
      newgeonames <- c("old_id", "zipcode", "city", "stateabb", "msa", "county")
      setnames(df, old = geo_names, new = newgeonames)
      
   } else if (identical(geo_names, geo_names_5)) {
      newgeonames <- c("old_id", "zipcode", "city", "county", "stateabb", "msa")
      setnames(df, old = geo_names, new = newgeonames)
      
   } else if (identical(geo_names, geo_names_6)) {
      newgeonames <- c("old_id", "zipcode", "stateabb")
      setnames(df, old = geo_names, new = newgeonames)
   }
   
   df[, zipcode := str_pad(as.character(zipcode), 5, pad = "0")]
   if ("RegionID" %in% geo_names) {
      df[, old_id := NULL]
      newgeonames <- newgeonames[-1]
   }
   if ("county" %in% newgeonames) df[, county := str_replace_all(county, " County", "")]

   save_data(df = df, key = newgeonames, 
             filename = file.path("../temp", basename(x)),
             nolog = T)
}

reshape_zillow <- function(infolder) {
   
   files <- list.files(infolder, pattern = "*.csv")
   
   value_names <- str_replace_all(files, "Zip_|.csv", "")
   value_names <- fix_varnames_zipcode(value_names)
   
   id_fullvars <- c("zipcode", "city", "county", "msa", "stateabb")
   
   dt_zillow <- mapply(reshape_single_file,
                       filename = files, valname = value_names,
                       MoreArgs = list(infolder, id_fullvars), SIMPLIFY = F)
   
   return(dt_zillow)
}

reshape_single_file <- function(filename, valname, infolder, id_fullvars) {
   
   dt <- fread(file.path(infolder, filename), stringsAsFactors = F)
   
   idvars <- colnames(dt)
   idvars <- idvars[!str_detect(idvars, "[0-9]")]
   
   dt <- melt(dt, id.vars = idvars,
              variable.name = 'date', value.name = valname)
   
   missing_id_vars <- setdiff(id_fullvars, idvars)
   dt[, (missing_id_vars) := ""]
   
   return(dt)
}

merge_zillow <- function(l, key) {
   
   geovars <- c('zipcode', 'city', 'msa', 'county', 'stateabb')
   geovars_exclude_zip <- geovars[-1]
   
   dt <- lapply(l, function(x) {
      state_name <- x[, ..geovars]
      state_name <- unique(state_name)
   })
   dt <- rbindlist(dt, use.names = T)
   
   dt <- as.data.frame(unique(dt))
   dt[dt == ""] <- NA
   
   dt <- setDT(dt)[,lapply(.SD, function(y) y[!is.na(y)]),
                                 by = c('zipcode', 'city', 'msa', 'county')]
   dt <- dt[, city := str_replace_all(city, "^Town of | Township$", "")]
   
   dt <- dt[, lapply(.SD, function(y) y[!is.na(y)]),
                          by = c('zipcode', 'city', 'msa', 'county')]
   dt <- unique(dt)
   
   ## SH: What are the following lines doing?
   dt <- dt[, totNA := rowSums(is.na(dt))]
   dt <- dt[, minNA := min(totNA), by = zipcode][totNA == minNA, ]
   
   setkey(dt, 'zipcode')
   dt <- dt[J(unique(zipcode)), mult = "first"]
   
   dt[, c('totNA', 'minNA') := NULL]
   ## up to here?
   
   l <- lapply(l, function(y) y[, (geovars_exclude_zip) := NULL])
   
   file_combined <- Reduce(function(...) merge(..., all = T, by = key), l)
   file_combined <- setDT(dt)[file_combined, on = 'zipcode']
   
   setorder(file_combined, zipcode, date)
   
   return(file_combined)
}

# Execute
main()
