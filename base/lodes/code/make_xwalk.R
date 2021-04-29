
make_xwalk_od <- function(instub) {

  xwalk_files <- list.files('../../../raw/crosswalk/lodes/', 
                            full.names = T, pattern = "*.gz")
  xwalk <- rbindlist(lapply(xwalk_files, function(x) fread(x)))

  setnames(xwalk, old = c('tabblk2010', 'trct'), 
                  new = c('blockfips', 'tract_fips'))
  
  xwalk[, tract_fips := as.numeric(tract_fips)]

  xwalk <- xwalk[, c('blockfips', 'tract_fips', 'st')]
  
  tract_zip_xwalk <- fread(paste0(instub, "tract_zip_master.csv"), 
                 colClasses = c('numeric', 'numeric', 'numeric'))
  
  return(list(xwalk, tract_zip_xwalk))
}

make_xwalk_raw_wac <- function(instub) {
  xwalk_files <- list.files(paste0(instub, 'lodes/'), full.names = T)

  xwalk <- rbindlist(lapply(xwalk_files, function(x) fread(x)))
  
  setnames(xwalk, old = c('tabblk2010', 'trct'),
           new = c('blockfips', 'tract_fips'))
  target_xwalk <- c('blockfips', 'tract_fips', 'st')
  xwalk[, tract_fips := as.numeric(tract_fips)]
  xwalk <- xwalk[, ..target_xwalk]
  
  return(xwalk)
}

make_xwalk_raw_wac_county <- function(instub) {
  xwalk_files <- list.files(paste0(instub, 'lodes/'), full.names = T)
  
  xwalk <- rbindlist(lapply(xwalk_files, function(x) fread(x)))
  
  setnames(xwalk, old = c('tabblk2010', 'cty'), 
           new = c('blockfips', 'countyfips'))

  target_xwalk <- c('blockfips', 'countyfips', 'st')
  xwalk[, countyfips := as.numeric(countyfips)]
  xwalk <- xwalk[, ..target_xwalk]
  
  return(xwalk)
}


make_xwalk_tractzip <- function(instub) {
  xwalk <- fread(paste0(instub, "tract_zip_master.csv"), 
                 colClasses = c('numeric', 'numeric', 'numeric'))

  return(xwalk)
}
