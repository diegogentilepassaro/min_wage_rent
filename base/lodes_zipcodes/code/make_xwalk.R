
make_xwalk_raw_wac <- function(instub) {
  xwalk_files <- list.files(instub, full.names = T)

  xwalk <- rbindlist(lapply(xwalk_files, function(x) fread(x, colClasses = "numeric")))
  
  setnames(xwalk, old = c('tabblk2010', 'trct'),
                  new = c('blockfips', 'tract_fips'))
  
  target_xwalk <- c('blockfips', 'tract_fips', 'st')
  xwalk <- xwalk[, ..target_xwalk]
  
  return(xwalk)
}
