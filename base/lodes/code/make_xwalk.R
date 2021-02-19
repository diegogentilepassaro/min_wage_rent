
make_xwalk_od <- function(instub) {

  xwalk_files <- list.files(paste0(instub, 'lodes/'), 
                            full.names = T, pattern = "*.gz")
  xwalk <- rbindlist(lapply(xwalk_files, function(x) fread(x)))

  setnames(xwalk, old = c('tabblk2010', 'trct'), 
                  new = c('blockfips', 'tract_fips'))
  
  xwalk[, tract_fips := as.numeric(tract_fips)]

  xwalk <- xwalk[, c('blockfips', 'tract_fips', 'st')]
  
  tract_zip_xwalk <- read_excel(paste0(instub, "TRACT_ZIP_122019.xlsx"), 
                                col_names = c('tract_fips', 'zipcode', 'res_ratio', 
                                              'bus_ratio', 'oth_ratio', 'tot_ratio'),
                                col_types = rep('numeric', 6))
  tract_zip_xwalk <- setDT(tract_zip_xwalk)

  tract_zip_xwalk[, c('res_ratio', 'bus_ratio', 'oth_ratio') := NULL]
  tract_zip_xwalk <- tract_zip_xwalk[!is.na(zipcode), ]
  
  return(list(xwalk, tract_zip_xwalk))
}

make_xwalk_raw_wac <- function(instub) {
  xwalk_files <- list.files(paste0(instub, 'lodes/'), full.names = T)

  xwalk <- rbindlist(lapply(xwalk_files, function(x) fread(x)))
  
  setnames(xwalk, old = c('tabblk2010', 'trct'), new = c('blockfips', 'tract_fips'))
  target_xwalk <- c('blockfips', 'tract_fips', 'st')
  xwalk[, tract_fips := as.numeric(tract_fips)]
  xwalk <- xwalk[, ..target_xwalk]
  
  return(xwalk)
}
