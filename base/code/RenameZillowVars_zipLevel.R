source("../../lib/R/library.R")
load_packages(c('tidyverse', 'data.table'))

main <- function() {
   
   datadir <- '../../raw_data/zillow/'
   outputdir <- "../output/"
   
   rename_zillow_vars(infiles = datadir, outdir = outputdir)
}

rename_zillow_vars <- function(infiles, outdir){
   filenames <- list.files(infiles)
   filenames <- filenames[str_detect(filenames, "Zip_*")]
   filenames <- filenames[!str_detect(filenames, "_Summary.csv")]
   
   oldnames = c('RegionName', 'City', 'State', 'Metro', 'CountyName')
   newnames = c('zipcode', 'city', 'stateabb', 'msa', 'county')
   
   format <- lapply(filenames, function(x) {
      
      df <- data.table::fread(paste0(infiles, x), stringsAsFactors = F)
      df[,SizeRank:=NULL]
      data.table::setnames(df, old = oldnames, new = newnames)
      df[, county := str_replace_all(county, " County", "")]
      
      save_data(df = df, key = newnames,
                filename = paste0(outdir, x))
   })
}

main()
