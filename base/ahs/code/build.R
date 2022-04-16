remove(list = ls())

library(data.table)

main <- function() {
  in_raw <- '../../../drive/raw_data/ahs'
  out_data <- '../../../drive/base_large/ahs'
  
  varchar <- c('COUNTY', 'STATE', 'SMSA', 'METRO')
  
  varnum <- c('ZINC', 'ZINC2', 'HHPQSAL', 'RENT', 'TYPE', 'NUNITS', 'TENURE',
              'UNITSF', 'CONDO', 'BEDRMS')
  
  vars <- c(varchar, varnum)
  
  data <- lapply(list(2011, 2013),
    \(yy) fread(file.path(in_raw, 
                          paste('AHS', yy, 'Metropolitan PUF'),
                          'household.csv'), 
                select = vars, quote = "'", 
                colClasses = list(character = varchar, 
                                  numeric   = varnum))[, year := yy])
  
  data <- rbindlist(data, fill=TRUE)
  
  data[,NUNITS_cat := fcase(
    NUNITS == 1         , 'Single Unit',
    NUNITS == 2         , '2 apartments',
    NUNITS %in% c(3, 4) , '3 to 4 apartments',
    NUNITS > 4          , '5+ apartments')]
  
  data[, NUNITS_cat := factor(NUNITS_cat, 
                           levels = c('Single Unit', '2 apartments',
                                      '3 to 4 apartments','5+ apartments'))]
  
  fwrite(data, file.path(out_data, 'ahs_household_2011_2013.csv'))
  
}

main()
