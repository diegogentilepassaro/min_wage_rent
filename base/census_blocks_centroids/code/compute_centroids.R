remove(list = ls())

library(sf)
library(dplyr)
library(data.table)

main <- function(){
  instub  <- "../temp"
  outstub <- "../../../drive/base_large/census_blocks_centroids"
  
  files <- list.files(path = instub, pattern = "*.shp$")

  cb_centroids <- data.frame()
  for (file in files){
    cb_file_centroids <- compute_centroids(instub, file)
    cb_centroids      <- rbind(cb_centroids, cb_file_centroids)
  }

  st_write(cb_centroids, 
           file.path(outstub, "census_blocks_2010_centroids.shp"))
}

compute_centroids <- function(instub, file){

  spf <- read_sf(file.path(instub, file)) %>%
    select(STATEFP10, COUNTYFP10, TRACTCE10,
           BLOCKID10, HOUSING10, POP10) %>%
    rename(statefips = STATEFP10,
           countyfips = COUNTYFP10, 
           census_tract = TRACTCE10,
           census_block = BLOCKID10, 
           num_houses10 = HOUSING10,
           pop10 = POP10)

  spf           <- spf[st_is_valid(spf),]
  spf_centroids <- st_centroid(spf)

  return(spf_centroids)
}


main()
