# Preliminaries
source("../../lib/R/library.R")
load_packages(c('tidyverse', 'data.table'))

dir.create("../output/zillow/")

datadir <- '../../raw_data/zillow/'
tempdir <- "../temp/"
outputdir <- "../output/zillow/"


main <- function() {
   rename_zillow_vars()
}


rename_zillow_vars <- function(){
   filenames <- list.files(paste0(datadir))
   filenames <- filenames[str_detect(filenames, "Zip_*")]
   filenames <- filenames[!str_detect(filenames, "_Summary.csv")]
   
   oldnames = c('RegionName', 'City', 'State', 'Metro', 'CountyName')
   newnames = c('zipcode', 'city', 'stateabb', 'msa', 'county')
   
   format <- lapply(filenames, function(x) {
      
      df <- data.table::fread(paste0(datadir, x), stringsAsFactors = F)
      df[,SizeRank:=NULL]
      data.table::setnames(df, old = oldnames, new = newnames)
      df[, county := str_replace_all(county, " County", "")]
      
      save_data(df = df, key = newnames,
                filename = paste0(outputdir, x))
   })
}


main()
