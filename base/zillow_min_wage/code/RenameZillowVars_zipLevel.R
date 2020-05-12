remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")

load_packages(c('tidyverse', 'data.table'))

main <- function() {
   
   datadir   <- '../../../drive/raw_data/zillow/'
   outputdir <- "../output/"
   geounit   <- "Zip"

   last_period <- "122019"
   
   rename_zillow_vars(infiles = paste0(datadir, geounit, "_", last_period, "/"), 
                      outdir = outputdir)
}

rename_zillow_vars <- function(infiles, outdir){
   filenames <- list.files(infiles)
   filenames <- filenames[str_detect(filenames, "^Zip_*")]
   filenames <- filenames[!str_detect(filenames, "_Summary.csv")]

   format <- lapply(filenames, function(x) {
      df <- data.table::fread(paste0(infiles, x), stringsAsFactors = F)
      df[,c("DataTypeDescription", "SizeRank", "RegionType"):=NULL]
      
      colgeonames <- colnames(df)
      colgeonames <- colgeonames[!str_detect(colgeonames, "[0-9]")]
      
      colgeo_type1 <- c("RegionName", "City", "CountyName", "Metro", "StateFullName")
      colgeo_type2 <- c("RegionID", "RegionName", "City", "County", "State", "Metro")
      colgeo_type3 <- c("RegionName", "City", "State", "Metro", "CountyName")
      colgeo_type4 <- c("RegionID", "RegionName", "City", "State", "Metro", "CountyName")
      colgeo_type5 <- c("RegionID", "RegionName", "City", "County", "State", "Metro")
      
      if (identical(colgeonames,colgeo_type1)) {
         newgeonames <- c("zipcode", "city", "county", "msa", "statename")
         data.table::setnames(df, old = colgeonames, 
                              new = newgeonames)
         df[, county := str_replace_all(county, " County", "")]

         save_data(df = df, key = newgeonames,
                   filename = paste0(outdir, x))
      } else if (identical(colgeonames,colgeo_type2)) {
         newgeonames <- c("old_id", "zipcode", "city", "county", "stateabb", "msa")
         data.table::setnames(df, old = colgeonames, 
                              new = newgeonames)
         df[, county := str_replace_all(county, " County", "")]
         df[,old_id := NULL]
         newgeonames <- newgeonames[-1]
         
         save_data(df = df, key = newgeonames,
                   filename = paste0(outdir, x))
      } else if (identical(colgeonames,colgeo_type3)) {
         newgeonames <- c("zipcode", "city", "stateabb", "msa", "county")
         data.table::setnames(df, old = colgeonames, 
                              new = newgeonames)
         df[, county := str_replace_all(county, " County", "")]
         
         save_data(df = df, key = newgeonames,
                   filename = paste0(outdir, x))
      } else if (identical(colgeonames,colgeo_type4)) {
         newgeonames <- c("old_id", "zipcode", "city", "stateabb", "msa", "county")
         data.table::setnames(df, old = colgeonames, 
                              new = newgeonames)
         df[, county := str_replace_all(county, " County", "")]
         df[,old_id := NULL]
         newgeonames <- newgeonames[-1]
         
         save_data(df = df, key = newgeonames,
                   filename = paste0(outdir, x))
      } else if (identical(colgeonames,colgeo_type5)) {
         newgeonames <- c("old_id", "zipcode", "city", "county", "stateabb", "msa")
         data.table::setnames(df, old = colgeonames, 
                              new = newgeonames)
         df[, county := str_replace_all(county, " County", "")]
         df[,old_id := NULL]
         newgeonames <- newgeonames[-1]
         
         save_data(df = df, key = newgeonames,
                   filename = paste0(outdir, x))
      }
   })
}

main()