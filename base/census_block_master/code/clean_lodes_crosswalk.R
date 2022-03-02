remove(list = ls())

library(data.table)

main <- function(){
  instub  <- "../../../drive/raw_data/lodes_crosswalks"
  outstub <- "../temp"
  
  geos <- c("tabblk2010", "st", "cty", "ctyname",
            "trct", "bgrp", "cbsa", "zcta", "stplc", "stplcname")

  files <- list.files(instub, pattern = ".gz$")
  
  dt <- data.table()
  for (file in files) {
    dt_state <- fread(file.path(instub, file),
                      select = list("character" = geos))
    
    setnames(dt_state, old = geos, 
              new = c("block", "statefips", 
                      "countyfips", "countyfips_name",
                      "tract", "blockgroup", "cbsa", 
                      "zcta", "place_code", "place_name"))
    
    dt <- rbindlist(list(dt, dt_state))
  }
  
  fwrite(dt, file.path(outstub, "cb_lodes_crosswalk.csv"))
}

main()
