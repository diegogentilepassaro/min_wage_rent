# Set dependencies
lib <- "../../lib/R/"
datadir <- '../../base/output/zillow/'
outputdir <- "../output/"
tempdir <- "../temp/"

# Import custom functions
source(paste0(lib, 'load_packages.R'))
source(paste0(lib, 'fwrite_key.R'))
source(paste0(lib, 'setkey_unique.R'))

# Import libraries
load_packages(c('tidyverse', 'data.table'))


main <- function(){
   filelist <- reshape_zillow_zip_level()
   merge_zillow(filelist)
}


reshape_zillow_zip_level <- function(){
   filenames <- list.files(paste0(datadir))
   filenames <- filenames[str_detect(filenames, "Zip_*")]
   filenames <- filenames[!str_detect(filenames, "_Summary.csv")]
   
   value_names <- c('rent2BR_median', 'rent2BR_psqft_median', 'rent_psqft_median_SFR', 'zhvi2BR')
   
   
   
   zillow_data <- mapply(function(filename, valname){
      idvars <- c('zipcode', 'city', 'stateabb', 'msa', 'county')

      data <- fread(paste0(datadir,filename), stringsAsFactors = F)
      data <- data.table::melt(data,
                                id.vars = idvars,
                                variable.name = 'date',
                                value.name = valname)
      setkey_unique(data, c('zipcode', 'date'))
      return(data)}, 
      filename = filenames, 
      valname = value_names, 
      SIMPLIFY = F)
   
   return(zillow_data)
}


merge_zillow <- function(l){
   idvars <- c('zipcode', 'city', 'stateabb', 'msa', 'county')
   mvars <- c(idvars, 'date')
   
   file_combined <-  Reduce(function(x,y,m = mvars){merge(x,y,all = T, by = m)}, l)
   data.table::setorder(file_combined, zipcode, date)
   
   file_combined[,date:=str_replace_all(date, "-", "_")]
   fwrite_key(file_combined, file = paste0(tempdir,"zillow_clean.csv"))
}



main()