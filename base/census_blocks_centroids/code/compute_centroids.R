remove(list = ls())

library(sf)
library(dplyr)
library(data.table)

main <- function(){
  in_stub <- "../temp"
  out_stub <- "../../../drive/base_large/census_blocks_centroids"
  
  
  files <- list.files(path = in_stub, pattern = "*.shp$")

  cb_centroids <- data.frame()
  for (file in files){
    cb_file_centroids <- compute_centroids(in_stub, file)
    cb_centroids <- rbind(cb_centroids, cb_file_centroids)
  }
  st_write(cb_centroids, paste0(out_stub, "/census_blocks_2010_centroids.shp"))
}

compute_centroids <- function(in_stub, file){
  spf <- read_sf(paste0(in_stub, "/", file)) %>%
    select(STATEFP10, COUNTYFP10, TRACTCE10,
           BLOCKID10, HOUSING10, POP10) %>%
    rename(statefips = STATEFP10,
           countyfips = COUNTYFP10, 
           census_tract = TRACTCE10,
           census_block = BLOCKID10, 
           num_houses10 = HOUSING10,
           pop10 = POP10)
  spf <- spf[st_is_valid(spf),]
  spf_centroids <- st_centroid(spf)

  return(spf_centroids)
}

main()
