remove(list = ls())

library(sf)
library(dplyr)
library(data.table)

main <- function(){
  instub  <- "../temp"
  outstub <- "../../../drive/base_large/assemble_place_shapefile"
  
  files <- list.files(path = instub, pattern = "*.shp$")

  places <- data.frame()
  for (file in files){
    state_places <- load_shapefile(instub, file)
    places       <- rbind(places, state_places)
  }
 st_write(places,
         file.path(outstub, "us_places_2010.shp"))
}

load_shapefile <- function(instub, file){

  spf <- read_sf(file.path(instub, file))  %>%
    select(STATE, PLACE, NAME, LSAD) %>%
    rename(statefips = STATE,
           place_code = PLACE,
           place_name = NAME,
           place_type = LSAD)
  spf <- spf[st_is_valid(spf),]

  return(spf)
}


main()
