remove(list = ls())

library(data.table)

source('../../../lib/R/save_data.R')

main <- function() {
  in_raw <- '../../../drive/raw_data/ahs'
  out_data <- '../../../drive/base_large/ahs'
  
  varchar <- c('COUNTY', 'STATE', 'SMSA', 'METRO', 'CONTROL')
  
  # Household section
  
  varnum <- c('ZINC', 'ZINC2', 'HHPQSAL', 'RENT', 'TYPE', 'NUNITS', 'TENURE',
              'UNITSF', 'CONDO', 'BEDRMS', 'PER')

  data_hh <- load_data('household', varchar, varnum, in_raw)
  
  data_hh[,NUNITS_cat := fcase(
    NUNITS == 1         , '1 unit',
    NUNITS == 2         , '2 units',
    NUNITS %in% c(3, 4) , '3 to 4 units',
    NUNITS > 4          , '5+ units')]
  
  save_data(data_hh, 'CONTROL',
            file.path(out_data, 'ahs_household_2011_2013.csv'),
            logfile = '../output/data_manifest.txt')
  
  # Person section
  
  varnum <- c('REL', 'SAL', 'PLINE')

  data_per  <- load_data('person', varchar, varnum, in_raw)
  
  save_data(data_per, c('CONTROL', 'PLINE'),
            file.path(out_data, 'ahs_person_2011_2013.csv'),
            logfile = '../output/data_manifest.txt')
  
}

load_data <- function(survey, varchar, varnum, in_raw) {
  
  vars <- c(varchar, varnum)
  
  data <- lapply(list(2011, 2013),
                 \(yy) fread(file.path(in_raw, 
                                       paste('AHS', yy, 'Metropolitan PUF'),
                                       paste0(survey, '.csv')), 
                             select = vars, quote = "'", 
                             colClasses = list(character = varchar, 
                                               numeric   = varnum))[, year := yy])
  
  data <- rbindlist(data, fill=TRUE)
  
  setkey(data, CONTROL, year)
  
  return(data)
}

main()
