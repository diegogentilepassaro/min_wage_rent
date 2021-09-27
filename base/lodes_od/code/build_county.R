remove(list = ls())
options(scipen=999)

paquetes <- c("stringr", "data.table", "bit64", "parallel")
lapply(paquetes, require, character.only = TRUE)

source("../../../lib/R/save_data.R")
source("make_xwalk.R")

library(parallel)
n_cores <- 10

main <- function(paquetes, n_cores) {
  instub  <- "../../../drive/raw_data/lodes"
  outstub <- "../../../drive/base_large/lodes_od"
  
  for (yy in 2009:2018) {
    # Prepare states od matrices
    files <- list.files(file.path(instub, yy, "od", "JT00"),
                        full.names = T, pattern = "*.gz")
    files <- files[!grepl("pr", files)]          # Ignore Puerto Rico
    
    files_main <- files[grepl("_main_", files)]
    files_aux  <- files[grepl("_aux_", files)]
    
    state_list <- c(tolower(state.abb), "dc")
    
    dt_aux <- rbindlist(lapply(files_aux, fread))
    dt_aux[, h_statefips := as.numeric(substr(str_pad(h_geocode, 15, pad = 0), 1, 2))]
    dt_aux[, createdate := NULL]
    
    # Parallel set-up
    cl <- makeCluster(n_cores, type = "PSOCK")   # Create cluster. Use type = "FORK" in Mac
    
    clusterExport(cl, "paquetes")                                         # Load "paquetes" object in nodes
    clusterEvalQ(cl, lapply(paquetes, require, character.only = TRUE))    # Load packages in nodes
    clusterExport(cl, "make_odmatrix_state", env = .GlobalEnv)            # Load global environment objects in nodes
    clusterExport(cl, c("instub", "dt_aux"), 
                  env = environment())                                # Load local environment objects in nodes
    
    odcounty_list <- parLapply(cl, files_main, function(ff) {
      make_odmatrix_state(file_ = ff, aux = dt_aux)
    })
    stopCluster(cl)
    
    # Save OD matrices  
    for (state in odcounty_list) {
      save_data(state$dt, key = c("h_countyfips", "w_countyfips"),
                filename = file.path(outstub, yy, paste0("odcounty_", state$fips, ".csv")),
                logfile  = "../output/odmatrix_data_manifest.log")
    }
  }
}


make_odmatrix_state <- function(file_, aux, xwalk) {
  
  target_vars <- c("S000", 
                   "SA01", "SA02", "SA03", 
                   "SE01", "SE02", "SE03", 
                   "SI01", "SI02", "SI03")
  new_names   <- c("jobs_tot",
                   "jobs_age_under29",     "jobs_age_30to54",        "jobs_age_above55",
                   "jobs_earn_under1250",  "jobs_earn_1250_3333",    "jobs_earn_above3333",
                   "jobs_goods_producing", "jobs_trade_transp_util", "jobs_other_service_industry")
  
  dt_main <- fread(file_, select = c("w_geocode", "h_geocode", target_vars))
  
  st_fips  <- as.numeric(substr(str_pad(dt_main$h_geocode[1], 15, pad = 0), 1, 2))
  
  dt_main <- rbindlist(list(dt_main, 
                            aux[h_statefips == st_fips][, h_statefips := NULL]))
  
  setnames(dt_main, old = target_vars, new = new_names)
  
  # Collapse at tract level
  dt_main[, w_countyfips := as.numeric(substr(str_pad(w_geocode, 15, pad = 0), 1, 5))]
  dt_main <- dt_main[, lapply(.SD, sum, na.rm = T),
                           .SDcols = new_names, 
                           by = c("h_geocode", "w_countyfips")]

  dt_main[, h_countyfips := as.numeric(substr(str_pad(h_geocode, 15, pad = 0), 1, 5))]
  dt_main <- dt_main[, lapply(.SD, sum, na.rm = T),
                           .SDcols = new_names,
                           by = c("h_countyfips", "w_countyfips")]
  
  return(list("dt"   = dt_main,
              "fips" = str_pad(st_fips, 2, pad = 0)))
}

# Execute
main(paquetes, n_cores) 
