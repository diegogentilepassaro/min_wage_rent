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
  datadir_lodes       <- "../../../drive/raw_data/lodes/od/JT00/2017"
  datadir_xwalk_lodes <- "../../../raw/crosswalk"
  outdir              <- "../../../drive/base_large/lodes"
  
  # Prepare crosswalks 
  blc_cty_xwalk <- make_xwalk_raw_wac_county(datadir_xwalk_lodes)
  
  # Prepare states od matrices
  files <- list.files(datadir_lodes, 
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
  clusterExport(cl, c("datadir_lodes", "aux_all"), 
                env = environment())                                # Load local environment objects in nodes
  
  odcounty_list <- parLapply(cl, state_list, function(y) {
    make_odmatrix_state(stabb = y, datadir = datadir_lodes,
                        aux = aux_all)
  })
  stopCluster(cl)
  
  # Save OD matrices  
  for (state in odcounty_list) {
    save_data(state$dt, key = c("h_countyfips", "w_countyfips"),
              filename = file.path(outdir, paste0("odcounty_", state$fips, ".csv")),
              logfile  = "../output/odmatrix_data_manifest.log")
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
  this_state[, w_countyfips := as.numeric(substr(str_pad(w_geocode, 15, pad = 0), 1, 5))]
  this_state <- this_state[, lapply(.SD, sum, na.rm = T),
                           .SDcols = c("totjob", "job_young", "job_lowinc"), 
                           by = c("h_geocode", "w_countyfips")]

  this_state[, h_countyfips := as.numeric(substr(str_pad(h_geocode, 15, pad = 0), 1, 5))]
  this_state <- this_state[, lapply(.SD, sum, na.rm = T),
                           .SDcols = c("totjob", "job_young", "job_lowinc"),
                           by = c("h_countyfips", "w_countyfips")]
  
  # Keep destination zipcodes that make up to `dest_threshold` percent of total workforce
  this_state <- this_state[order(h_countyfips, -totjob)]
  
  this_state[, h_totjob     := sum(totjob, na.rm = T), by = "h_countyfips"]
  this_state[, totjob_cum   := cumsum(totjob), by = "h_countyfips"] 
  this_state[, totjob_cumsh := totjob_cum / h_totjob]
  
  this_state <- this_state[totjob_cumsh <= dest_threshold, ]
  this_state[, c("h_totjob", "totjob_cum", "totjob_cumsh") := NULL] 
  this_state[, h_countyfips := str_pad(h_countyfips, 5, pad = 0)]
  this_state[, w_countyfips := str_pad(w_countyfips, 5, pad = 0)]
  
  return(list("dt"   = this_state,
              "fips" = str_pad(this_fips, 2, pad = 0)))
}

# Execute
main(paquetes, n_cores) 
