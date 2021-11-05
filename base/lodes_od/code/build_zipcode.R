remove(list = ls())

paquetes <- c("stringr", "data.table", "bit64", "parallel")
lapply(paquetes, require, character.only = TRUE)

source("../../../lib/R/save_data.R")
source("make_xwalk.R")
options(scipen = 999)


library(parallel)
n_cores <- 10

# Note: See README in source/raw/lodes for a few missing state-years

main <- function(paquetes, n_cores) {
  in_lodes       <- "../../../drive/raw_data/lodes"
  in_xwalk       <- "../../geo_master/output"
  in_xwalk_lodes <- "../../../raw/crosswalk/lodes"
  outstub         <- "../../../drive/base_large/lodes_od"

  # Prepare crosswalks 
  blc_tract_xwalk <- make_xwalk_raw_wac(in_xwalk_lodes)
  tract_zip_xwalk <- fread(file.path(in_xwalk, "tract_zip_master.csv"), 
                           colClasses = c("numeric", "character", "numeric"))
  
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
    clusterExport(cl, c("in_lodes", "dt_aux", "tract_zip_xwalk"), 
                      env = environment())                                # Load local environment objects in nodes
  
    odzip_list <- parLapply(cl, files_main, function(ff) {
      make_odmatrix_state(file_ = ff, year = yy,
                          aux = dt_aux, xwalk = tract_zip_xwalk)
    })
    stopCluster(cl)
    
    # Save OD matrices
    for (state in odzip_list) {
      save_data(state$dt, key = c("r_zipcode", "w_zipcode"),
                filename = file.path(outstub, yy, paste0("odzip_", state$fips, ".csv")),
                logfile  = "../output/odmatrix_data_manifest.log")
    }
  }
}


make_odmatrix_state <- function(file_, year, aux, xwalk) {
  
  target_vars <- c("S000", 
                   "SA01", "SA02", "SA03", 
                   "SE01", "SE02", "SE03", 
                   "SI01", "SI02", "SI03")
  new_names   <- c("jobs_tot",
                   "jobs_age_under29",     "jobs_age_30to54",        "jobs_age_above55",
                   "jobs_earn_under1250",  "jobs_earn_1250_3333",    "jobs_earn_above3333",
                   "jobs_goods_producing", "jobs_trade_transp_util", "jobs_other_service_industry")
  
  dt_main <- fread(file_, select = c("w_geocode", "h_geocode", target_vars))
  
  # Add auxiliary to main
  st_fips  <- as.numeric(substr(str_pad(dt_main$h_geocode[1], 15, pad = 0), 1, 2))
  dt_main <- rbindlist(list(dt_main, 
                            aux[h_statefips == st_fips][, h_statefips := NULL]))
  
  setnames(dt_main, old = target_vars, new = new_names)
  
  # Collapse at tract level
  dt_main[, w_tractfips := as.numeric(substr(str_pad(w_geocode, 15, pad = 0), 1, 11))]
  dt_main <- dt_main[, lapply(.SD, sum, na.rm = T),
                     .SDcols = new_names, 
                     by = c("h_geocode", "w_tractfips")]
  
  dt_main[, h_tractfips := as.numeric(substr(str_pad(h_geocode, 15, pad = 0), 1, 11))]
  dt_main <- dt_main[, lapply(.SD, sum, na.rm = T),
                      .SDcols = new_names,
                      by = c("h_tractfips", "w_tractfips")]
  
  # Crosswalk destination tract to zipcode for each origin tract separately
  tract_to_zip_work <- function(dt, xwlk = xwalk, vars = new_names) {

    dt <- dt[xwlk, on = c("w_tractfips" = "tract_fips"), nomatch = 0]
    dt <- dt[, lapply(.SD, 
             function(x, w) sum(x*w, na.rm = T), w = res_ratio), 
             .SDcols = vars, 
             by = c("h_tractfips", "zipcode")]
    
    setnames(dt, old = "zipcode", new = "w_zipcode")
    return(dt)
  }

  # Crosswalk origin tract to zipcode for each destination zipcode separately
  tract_to_zip_home <- function(dt, xwlk = xwalk, vars = new_names) {

    dt <- dt[xwlk, on = c("h_tractfips" = "tract_fips"), nomatch = 0]
    dt <- dt[, lapply(.SD, 
                      function(x, w) sum(x*w, na.rm = T), w = res_ratio),
                      .SDcols = vars, 
                      by = c("w_zipcode", "zipcode")]
    
    setnames(dt, old = "zipcode", new = "r_zipcode")
    
    return(dt)
  }
  
  dt_zip <- split(dt_main, by = "h_tractfips")
  dt_zip <- rbindlist(lapply(dt_zip, tract_to_zip_work))
  dt_zip <- split(dt_zip, by = "w_zipcode")
  dt_zip <- rbindlist(lapply(dt_zip, tract_to_zip_home))
  
  return(list("dt"   = dt_zip,
              "fips" = str_pad(st_fips, 2, pad = 0)))
}

# Execute
main(paquetes, n_cores) 
