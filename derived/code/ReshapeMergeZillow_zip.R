# Preliminaries
source("../../lib/R/library.R")
load_packages(c('tidyverse', 'data.table', 'tidycensus'))

main <- function(){
   datadir <- '../../base/output/zillow/'
   tempdir <- "../temp/"
   
   filelist <- reshape_zillow_zip_level(infiles = datadir)
   merge_zillow(l = filelist, outstub = paste0(tempdir,"zillow_clean.csv"),
                key = c('zipcode', 'date'))
}


reshape_zillow_zip_level <- function(infiles){
   
   filenames <- list.files(infiles)
   filenames <- filenames[str_detect(filenames, "Zip_*")]
   filenames <- filenames[!str_detect(filenames, "_Summary.csv")]
   
   value_names <- c('rent2BR_median', 'rent2BR_psqft_median', 'rent_psqft_median_SFR', 'zhvi2BR')
   
   zillow_data <- mapply(function(filename, valname){
            idvars <- c('zipcode', 'city', 'stateabb', 'msa', 'county')
            
            data <- fread(paste0(infiles, filename), stringsAsFactors = F)
            data <- data.table::melt(data,
                                     id.vars = idvars,
                                     variable.name = 'date',
                                      value.name = valname)
            return(data)}, 
      filename = filenames,
      valname = value_names,
      SIMPLIFY = F)
   
   return(zillow_data)
}

merge_zillow <- function(l, outstub, key){
   idvars <- c('zipcode', 'city', 'stateabb', 'msa', 'county')
   mvars <- c(idvars, 'date')
   
   file_combined <-  Reduce(function(x,y,m = mvars){merge(x,y,all = T, by = m)}, l)
   data.table::setorder(file_combined, zipcode, date)
   
   file_combined[,date:=str_replace_all(date, "-", "_")]
   save_data(file_combined, file = outstub, key = key, nolog = TRUE)
}

main()
