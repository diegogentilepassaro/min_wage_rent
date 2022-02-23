remove(list = ls())

paquetes <- c("sf", "dplyr")
lapply(paquetes, require, character.only = TRUE)

library(parallel)
n_cores <- 4

set.seed(42)

main <- function(paquetes, n_cores) {

  instub  <- "../temp"
  outstub <- "../../../drive/base_large/census_blocks_centroids"
  
  logfile <- "../output/activity.txt"

  write(sprintf("%s: Conversion started.\n", Sys.time()), 
        file = logfile)
  
  files <- list.files(path = instub, pattern = "*.shp$")

  # Parallel set-up
  cl <- makeCluster(n_cores, type = "PSOCK")   # Create cluster. Use type = "FORK" in Mac
  
  clusterExport(cl, "paquetes")                                         # Load "paquetes" object in nodes
  clusterEvalQ(cl, lapply(paquetes, require, character.only = TRUE))    # Load packages in nodes
  clusterExport(cl, "compute_centroids",  env = .GlobalEnv)             # Load global environment objects in nodes
  clusterExport(cl, c("instub", "files"), env = environment())          # Load local environment objects in nodes
  
  write(sprintf("%s: Parallelization set, %s cores.\n", Sys.time(), n_cores), 
        file = logfile, append = T)

  centroids <- parLapply(cl, files, function(ff) {
    st_fips <- gsub("2010", "", gsub("[^0-9]", "", ff))
        
    spf <- compute_centroids(instub, ff)
    return(spf)
  })
  stopCluster(cl)
  
  centroids <- bind_rows(centroids)
  
  write(sprintf("%s: Conversion ended.\n", Sys.time()), 
        file = logfile, append = T)

  st_write(centroids,
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
           pop10        = POP10) %>%
    head(500)
  
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

# Execute
main(paquetes, n_cores) 
