remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")

load_packages(c('stringr', 'data.table'))

main <- function() {
   
   datadir   <- '../../../drive/raw_data/zillow/'
   outputdir <- "../output/"
   geounit   <- 

   last_period <- "122019"
   
   build_zipcode(indir  = file.path(datadir, "Zip_122019"), 
                 outdir = outputdir)
   #build_county
}

build_zipcode <- function(indir, outdir){
   files <- list.files(indir, pattern = "*.csv", full.names = T)
   files <- files[!str_detect(files, "_Summary.csv")]

   lapply(files, format_zillow)
   
   # Merge data
}

format_zillow <- function(x) {
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
      
      df[, county := str_replace_all(county, " County", "")]
      df[, zipcode := str_pad(as.character(zipcode), 5, pad = "0")]
      
      save_data(df = df, key = newgeonames,
                filename = file.path("../temp", basename(x)),
                nolog = T)
      
   } else if (identical(geo_names, geo_names_2)) {
      newgeonames <- c("old_id", "zipcode", "city", "county", "stateabb", "msa")
      setnames(df, old = geo_names, new = newgeonames)
      
      df[, county := str_replace_all(county, " County", "")]
      df[,old_id := NULL]
      newgeonames <- newgeonames[-1]
      df[, zipcode := str_pad(as.character(zipcode), 5, pad = "0")]
      
      save_data(df = df, key = newgeonames,
                filename = file.path("../temp", basename(x)),
                nolog = T)
      
   } else if (identical(geo_names, geo_names_3)) {
      newgeonames <- c("zipcode", "city", "stateabb", "msa", "county")
      setnames(df, old = geo_names, new = newgeonames)
      
      df[, county := str_replace_all(county, " County", "")]
      df[, zipcode := str_pad(as.character(zipcode), 5, pad = "0")]
      
      save_data(df = df, key = newgeonames,
                filename = file.path("../temp", basename(x)),
                nolog = T)
      
   } else if (identical(geo_names, geo_names_4)) {
      newgeonames <- c("old_id", "zipcode", "city", "stateabb", "msa", "county")
      setnames(df, old = geo_names, new = newgeonames)
      
      df[, county := str_replace_all(county, " County", "")]
      df[,old_id := NULL]
      newgeonames <- newgeonames[-1]
      df[, zipcode := str_pad(as.character(zipcode), 5, pad = "0")]
      
      save_data(df = df, key = newgeonames,
                filename = file.path("../temp", basename(x)),
                nolog = T)
      
   } else if (identical(geo_names, geo_names_5)) {
      newgeonames <- c("old_id", "zipcode", "city", "county", "stateabb", "msa")
      setnames(df, old = geo_names, new = newgeonames)
      
      df[, county := str_replace_all(county, " County", "")]
      df[,old_id := NULL]
      newgeonames <- newgeonames[-1]
      df[, zipcode := str_pad(as.character(zipcode), 5, pad = "0")]
      
      save_data(df = df, key = newgeonames,
                filename = file.path("../temp", basename(x)),
                nolog = T)
      
   } else if (identical(geo_names, geo_names_6)) {
      newgeonames <- c("old_id", "zipcode", "stateabb")
      setnames(df, old = geo_names, new = newgeonames)
      
      df[, old_id := NULL]
      newgeonames <- newgeonames[-1]
      df[, zipcode := str_pad(as.character(zipcode), 5, pad = "0")]
      
      save_data(df = df, key = newgeonames, 
                filename = file.path("../temp", basename(x)),
                nolog = T)
   }
}

main()
