# Set dependencies
lib <- "../../lib/R/"
datadir <- '../../base/output/zillow/'
outputdir <- "../output/"
tempdir <- "../temp/"

# Import custom functions
source(paste0(lib, 'check_packages.R'))
source(paste0(lib, 'fwrite_key.R'))
source(paste0(lib, 'setkey_unique.R'))

# Import libraries
check_packages(c('tidyverse', 'data.table'))


main <- function(){
   filelist <- reshape_zillow_zip_level()
   merge_zillow(filelist)
}


reshape_zillow_zip_level <- function(){
   filenames <- list.files(paste0(datadir))
   filenames <- filenames[str_detect(filenames, "Zip_*")]
   filenames <- filenames[!str_detect(filenames, "_Summary.csv")]
   
   idvars <- c('zipcode', 'city', 'stateabb', 'msa', 'county')
   
   file1 <- fread(paste0(datadir,filenames[1]), stringsAsFactors = F)
   file1 <- data.table::melt(file1, 
                             id.vars = idvars,
                             variable.name = 'date', 
                             value.name = 'rent2BR_median')
   setkey_unique(file1, c('zipcode', 'date'))
   
   file2 <- fread(paste0(datadir,filenames[2]), stringsAsFactors = F)
   file2 <- data.table::melt(file2, 
                             id.vars = idvars,
                             variable.name = 'date', 
                             value.name = 'rent2BR_psqft_median')
   setkeyv(file2, c('zipcode', 'date'))
   
   
   file3 <- fread(paste0(datadir,filenames[3]), stringsAsFactors = F)
   file3 <- data.table::melt(file3, 
                             id.vars = idvars,
                             variable.name = 'date', 
                             value.name = 'rent_psqft_median_SFR')
   setkeyv(file3, c('zipcode', 'date'))
   
   file4 <- fread(paste0(datadir,filenames[4]), stringsAsFactors = F)
   file4 <- data.table::melt(file4, 
                             id.vars = idvars,
                             variable.name = 'date', 
                             value.name = 'zhvi2BR')
   setkeyv(file4, c('zipcode', 'date'))
   
   list(file1, file2, file3, file4)
}

merge_zillow <- function(l){
   idvars <- c('zipcode', 'city', 'stateabb', 'msa', 'county')
   mymerge <- function(x,y) {
      merge(x,y, all= T, by = c(idvars, 'date'))
   }
   
   file_combined <-  Reduce(mymerge, l)
   data.table::setorder(file_combined, zipcode, date)
   
   file_combined[,date:=str_replace_all(date, "-", "_")]
   fwrite_key(file_combined, file = paste0(tempdir,"zillow_clean.csv"))
}


main()