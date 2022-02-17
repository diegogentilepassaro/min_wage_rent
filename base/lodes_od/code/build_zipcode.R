remove(list = ls())
options(scipen = 999)

paquetes <- c("stringr", "data.table", "bit64", "parallel")
lapply(paquetes, require, character.only = TRUE)

source("../../../lib/R/save_data.R")

library(parallel)
n_cores <- 12

# Note: See README in source/raw/lodes for a few missing state-years

main <- function(paquetes, n_cores) {
  in_lodes <- "../../../drive/raw_data/lodes"
  in_xwalk <- "../../../drive/base_large/census_block_master"
  outstub  <- "../../../drive/base_large/lodes_od"

  # Prepare crosswalks 
  dt_xwalk <- load_xwalk(in_xwalk)
  
  for (yy in 2009:2018) {
    # Prepare states od matrices
    files <- list.files(file.path(in_lodes, yy, "od", "JT00"),
                        full.names = T, pattern = "*.gz")
    files <- files[!grepl("pr", files)]          # Ignore Puerto Rico
    
    files_main <- files[grepl("_main_", files)]
    files_aux  <- files[grepl("_aux_", files)]
    
    dt_aux <- rbindlist(lapply(files_aux, fread))
    dt_aux[, h_statefips := as.numeric(substr(str_pad(h_geocode, 15, pad = 0), 1, 2))]
    dt_aux[, createdate := NULL]
    
    # Parallel set-up
    cl <- makeCluster(n_cores, type = "PSOCK")   # Create cluster. Use type = "FORK" in Mac
    
    clusterExport(cl, "paquetes")                                         # Load "paquetes" object in nodes
    clusterEvalQ(cl, lapply(paquetes, require, character.only = TRUE))    # Load packages in nodes
    clusterExport(cl, "make_odmatrix_state", env = .GlobalEnv)            # Load global environment objects in nodes
    clusterExport(cl, c("in_lodes", "dt_aux", "dt_xwalk"), 
                      env = environment())                                # Load local environment objects in nodes
  
    # Make OD matrix
    odzip_list <- parLapply(cl, files_main, function(ff) {
      make_odmatrix_state(file_ = ff, year = yy,
                          aux = dt_aux, xwalk = dt_xwalk)
    })
    stopCluster(cl)
    
    # Save OD matrices
    for (state in odzip_list) {
      save_data(state$dt, key = c("r_zipcode", "w_zipcode"),
                filename = file.path(outstub, yy, paste0("odzip_", state$fips, ".csv")),
                logfile  = "../output/od_zipcode_data_manifest.log")
    }
  }
}

load_xwalk <- function(instub) {

  xwalk <- fread(file.path(instub, "census_block_master.csv"),
                 select = c("census_block", "zipcode"),
                 colClasses = c(zipcode = "character"))
  
  setnames(xwalk, old = c("census_block"), 
                  new = c("blockfips"))
  setkey(xwalk, "blockfips")

  return(xwalk)
}

make_odmatrix_state <- function(file_, year, aux, xwalk) {
  
  target_vars  <- c("S000", 
                    "SA01", "SA02", "SA03", 
                    "SE01", "SE02", "SE03", 
                    "SI01", "SI02", "SI03")
  new_varnames <- paste0("jobs_", 
                  c("tot",
                    "age_under29",     "age_30to54",        "age_above55",
                    "earn_under1250",  "earn_1250_3333",    "earn_above3333",
                    "goods_producing", "trade_transp_util", "other_service_industry"))
  
  dt_main <- fread(file_, select = c("w_geocode", "h_geocode", target_vars))
  
  # Add auxiliary to main
  st_fips  <- as.numeric(substr(str_pad(dt_main$h_geocode[1], 15, pad = 0), 1, 2))
  dt       <- rbindlist(list(dt_main, 
                             aux[h_statefips == st_fips][, h_statefips := NULL]))
  rm(dt_main)

  setnames(dt, old = c("w_geocode",   "h_geocode",   target_vars), 
               new = c("r_blockfips", "w_blockfips", new_varnames))
    
  # Add crosswalk to main data
  dt <- dt[xwalk, on = c("r_blockfips" = "blockfips"), nomatch = 0]    
  setnames(dt, old = "zipcode", new = "r_zipcode")

  dt <- dt[xwalk, on = c("w_blockfips" = "blockfips"), nomatch = 0]    
  setnames(dt, old = "zipcode", new = "w_zipcode")
  
  dt <- dt[, lapply(.SD, function(x) sum(x, na.rm = T)),
                    .SDcols = new_varnames,
                    by = c("r_zipcode", "w_zipcode")]
  
  return(list("dt"   = dt,
              "fips" = str_pad(st_fips, 2, pad = 0)))
}

# Execute
main(paquetes, n_cores) 
