add_missing_state_years <- function(od_files, instub, geo, yy) {
  
  if (geo == "countyfips") geo <- "county"
  else                     geo <- "zip"
  
  if (yy == 2009) {
    return(c(od_files, sprintf("%s/2010/od%s_11.csv", instub, geo), 
                       sprintf("%s/2011/od%s_25.csv", instub, geo)))
  } else if (yy == 2010) {
    return(c(od_files, sprintf("%s/2011/od%s_25.csv", instub, geo)))
  } else if (yy %in% c(2017, 2018)) {
    return(c(od_files, sprintf("%s/2016/od%s_02.csv", instub, geo)))
  } else {
    return(od_files)
  }
}
