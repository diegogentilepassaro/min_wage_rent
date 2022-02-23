remove(list = ls())
library(sf)
library(dplyr)

set.seed(42)

main <- function(){
  instub  <- "../temp"
  outstub <- "../../../drive/base_large/census_blocks_centroids"
  
  logfile <- file("../output/activity.txt")
  
  writeLines(c(sprintf("%s: Conversion started.", Sys.time())), logfile)
  
  files <- list.files(path = instub, pattern = "*.shp$")

  cb_centroids <- data.frame()
  for (filename in files){
    st_fips <- gsub("2010", "", gsub("[^0-9]", "", filename))
    
    writeLines(c(sprintf("%s: State %s begins", Sys.time(), st_fips)), logfile)
    
    cb_centroids <- compute_centroids(instub, filename)
    
    cb_centroids <- rbind(cb_centroids, cb_centroids)
  }
  
  writeLines(c(sprintf("%s: Conversion ended", Sys.time())), logfile)
  close(logfile)
  
  st_write(cb_centroids,
           file.path(outstub, "census_blocks_2010_centroids.shp"))
}

compute_centroids <- function(instub, filename){

  spf <- read_sf(file.path(instub, filename)) %>%
    select(STATEFP10, COUNTYFP10, TRACTCE10,
           BLOCKID10, HOUSING10, POP10) %>%
    rename(statefips    = STATEFP10,
           countyfips   = COUNTYFP10, 
           census_tract = TRACTCE10,
           census_block = BLOCKID10, 
           num_houses10 = HOUSING10,
           pop10        = POP10)
  
  spf      <- spf[st_is_valid(spf),] ## Is this necessary? It takes some time to check
  spf_cent <- st_centroid(spf)
  
  cent_own_poly <- 
    sapply(1:dim(spf)[1], function(i) {
      test <- st_intersects(spf_cent[i, ]$geometry, spf[i,]$geometry)[[1]]
      
      if (length(test) == 0) {  # When return is empty
        return(0)
      } else {
        return(1)
      }
    })
  
  spf$cent_own_poly      <- cent_own_poly
  spf_cent$cent_own_poly <- cent_own_poly
  
  if ( !(all(cent_own_poly == 1)) ) {
    
    spf_cent_new <- st_point_on_surface(spf %>% filter(cent_own_poly == 0))
    
    spf_cent <- bind_rows(spf_cent %>% filter(cent_own_poly == 1), 
                          spf_cent_new)
    
  }
  
  return(spf_cent)
}


main()
