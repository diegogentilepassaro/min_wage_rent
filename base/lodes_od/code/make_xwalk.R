
make_xwalk_od <- function(instub) {

  xwalk_files <- list.files('../../../raw/crosswalk/lodes/', 
                            full.names = T, pattern = "*.gz")
  xwalk <- rbindlist(lapply(xwalk_files, function(x) fread(x, colClasses = "numeric")))

  setnames(xwalk, old = c('tabblk2010', 'trct'), 
                  new = c('blockfips', 'tract_fips'))
  
  xwalk <- xwalk[, c('blockfips', 'tract_fips', 'st')]
  
  tract_zip_xwalk <- fread(file.path(instub, "tract_zip_master.csv"), 
                           colClasses = "numeric"))
  
  return(list(xwalk, tract_zip_xwalk))
}

make_xwalk_raw_wac <- function(instub) {
  xwalk_files <- list.files(instub, full.names = T)
  
  xwalk <- rbindlist(lapply(xwalk_files, function(x) fread(x, colClasses = "numeric")))
  
  setnames(xwalk, old = c('tabblk2010', 'trct'),
                  new = c('blockfips',  'tract_fips'))
  
  target_xwalk <- c('blockfips', 'tract_fips', 'st')
  xwalk <- xwalk[, ..target_xwalk]
  
  return(xwalk)
}


make_xwalk_raw_wac_county <- function(instub) {
  xwalk_files <- list.files(file.path(instub, 'lodes'), full.names = T)
  
  xwalk <- rbindlist(lapply(xwalk_files, function(x) fread(x, colClasses = "numeric")))
  
  setnames(xwalk, old = c('tabblk2010', 'cty'), 
                  new = c('blockfips', 'countyfips'))

  target_xwalk <- c('blockfips', 'countyfips', 'st')
  xwalk <- xwalk[, ..target_xwalk]
  
  return(xwalk)
}

