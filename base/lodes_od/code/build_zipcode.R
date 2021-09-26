remove(list = ls())
options(scipen=999)

source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")
source("make_xwalk.R")

paquetes <- c("stringr", "data.table", "bit64", "purrr", "parallel")
load_packages(paquetes)

library(parallel)
n_cores <- 10

main <- function(paquetes, n_cores) {
  in_lodes       <- "../../../drive/raw_data/lodes/"
  in_xwalk       <- "../../geo_master/output"
  in_xwalk_lodes <- "../../../raw/crosswalk"
  outdir         <- "../../../drive/base_large/lodes_od"

  # Prepare crosswalks 
  blc_tract_xwalk <- make_xwalk_raw_wac(in_xwalk_lodes)
  tract_zip_xwalk <- make_xwalk_tractzip(in_xwalk)

  for (yy in 2009:2018) {
    # Prepare states od matrices
    files <- list.files(in_lodes, 
                        full.names = T, pattern = "*.gz")
  
    files <- files[!grepl("pr", files)]          # Ignore Puerto Rico
    
    files_main <- files[grepl("_main_", files)]
    files_aux  <- files[grepl("_aux_", files)]
    
    state_list <- c(tolower(state.abb), "dc")
    
    aux_all <- rbindlist(lapply(files_aux, fread))
    aux_all[, h_statefips := as.numeric(substr(str_pad(h_geocode, 15, pad = 0), 1, 2))]
    
    # Parallel set-up
    cl <- makeCluster(n_cores, type = "PSOCK")   # Create cluster. Use type = "FORK" in Mac
    
    clusterExport(cl, "paquetes")                                         # Load "paquetes" object in nodes
    clusterEvalQ(cl, lapply(paquetes, require, character.only = TRUE))    # Load packages in nodes
    clusterExport(cl, "make_odmatrix_state", env = .GlobalEnv)            # Load global environment objects in nodes
    clusterExport(cl, c("in_lodes", "aux_all", "tract_zip_xwalk"), 
                      env = environment())                                # Load local environment objects in nodes
  
    odzip_list <- parLapply(cl, state_list, function(y) {
      make_odmatrix_state(stabb = y, datadir = in_lodes,
                          aux = aux_all, xwalk = tract_zip_xwalk)
    })
    stopCluster(cl)
    
    # Save OD matrices  
    for (state in odzip_list) {
      save_data(state$dt, key = c("h_zipcode", "w_zipcode"),
                filename = file.path(outdir, paste0("odzip_", state$fips, ".csv")),
                logfile  = "../output/odmatrix_data_manifest.log")
    }
  }
}


make_odmatrix_state <- function(stabb, datadir, aux, xwalk, dest_threshold = 1) {
  
  this_state <- fread(file.path(datadir, paste0(stabb, "_od_main_JT00_2017.csv.gz")))
  this_fips  <- as.numeric(substr(str_pad(this_state$h_geocode[1], 15, pad = 0),1 , 2))
  this_aux   <- aux[h_statefips==this_fips,][, h_statefips := NULL]

  this_state <- rbindlist(list(this_state, this_aux))
  
  this_state <- this_state[, c("w_geocode", "h_geocode", "S000", "SA01", "SE01")]
  setnames(this_state, old = c("S000",   "SA01",      "SE01"), 
                       new = c("totjob", "job_young", "job_lowinc"))
  
  # Collapse at tract level
  this_state[, w_tractfips := as.numeric(substr(str_pad(w_geocode, 15, pad = 0), 1, 11))]
  this_state <- this_state[, lapply(.SD, sum, na.rm = T),
                           .SDcols = c("totjob", "job_young", "job_lowinc"), 
                           by = c("h_geocode", "w_tractfips")]
  this_state[, h_tractfips := as.numeric(substr(str_pad(h_geocode, 15, pad = 0), 1, 11))]
  this_state <- this_state[, lapply(.SD, sum, na.rm = T),
                           .SDcols = c("totjob", "job_young", "job_lowinc"),
                           by = c("h_tractfips", "w_tractfips")]
  
  # Define function to crosswalk destination tract to zipcode for each origin tract separately
  tract_to_zip_work <- function(data, xwlk = xwalk) {

    data <- data[xwlk, on = c("w_tractfips" = "tract_fips"), nomatch = 0]
    data <- data[, lapply(.SD, function(x, w) sum(x*w, na.rm = T), w = res_ratio), 
                          .SDcols = c("totjob", "job_young", "job_lowinc"), 
                          by = c("h_tractfips", "zipcode")]
    
    setnames(data, old = "zipcode", new = "w_zipcode")
    return(data)
  }

  # Define function to crosswalk origin tract to zipcode for each destination zipcode separately
  tract_to_zip_home <- function(data, xwlk = xwalk) {

    data <- data[xwlk, on = c("h_tractfips" = "tract_fips"), nomatch = 0]
    data <- data[, lapply(.SD, function(x, w) sum(x*w, na.rm = T), w = res_ratio),
                          .SDcols = c("totjob", "job_young", "job_lowinc"), 
                          by = c("w_zipcode", "zipcode")]
    
    setnames(data, old = "zipcode", new = "h_zipcode")
    return(data)
  }
  
  this_state_zip <- split(this_state, by = "h_tractfips")
  this_state_zip <- rbindlist(lapply(this_state_zip, tract_to_zip_work))
  this_state_zip <- split(this_state_zip, by = "w_zipcode")
  this_state_zip <- rbindlist(lapply(this_state_zip, tract_to_zip_home))
  
  # Keep destination zipcodes that make up to `dest_threshold` percent of total workforce
  this_state_zip <- this_state_zip[order(h_zipcode, -totjob)]

  this_state_zip[, h_totjob     := sum(totjob, na.rm = T), by = "h_zipcode"]
  this_state_zip[, totjob_cum   := cumsum(totjob), by = "h_zipcode"] 
  this_state_zip[, totjob_cumsh := totjob_cum / h_totjob]

  this_state_zip <- this_state_zip[totjob_cumsh <= dest_threshold, ]
  this_state_zip[, c("h_totjob", "totjob_cum", "totjob_cumsh") := NULL]
  this_state_zip[, h_zipcode := str_pad(h_zipcode, 5, pad = 0)]
  this_state_zip[, w_zipcode := str_pad(w_zipcode, 5, pad = 0)]
  
  return(list("dt"   = this_state_zip,
              "fips" = str_pad(this_fips, 2, pad = 0)))
}

# Execute
main(paquetes, n_cores) 
