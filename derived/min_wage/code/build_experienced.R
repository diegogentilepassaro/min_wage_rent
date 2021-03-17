remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")

paquetes <- c("data.table", "usmap", "zoo")
load_packages(paquetes)

library(parallel)
n_cores <- 6

main <- function(){
  instub_mw    <- "../../../drive/derived_large/min_wage"
  instub_lodes <- "../../../drive/base_large/lodes"
  outstub      <- "../../../drive/derived_large/min_wage"
  log_file     <- "../output/data_file_manifest.log"
  
  dt.zip <- fread(file.path(instub_mw, "zip_statutory_mw.csv"))
  
  periods <- unique(dt.zip$year_month)
  states  <- fips(c(state.abb, 'DC'))
  
  # Parallel set-up
  cl <- makeCluster(n_cores, type = "PSOCK")   # Create cluster. Use type = "FORK" in Mac
  
  clusterExport(cl, "paquetes")                                         # Load "paquetes" object in nodes
  clusterEvalQ(cl, lapply(paquetes, require, character.only = TRUE))    # Load packages in nodes
  clusterExport(cl, "load_od_matrix", env = .GlobalEnv)                 # Load global environment objects in nodes
  clusterExport(cl, "assemble_expmw_state", env = .GlobalEnv)           # Load global environment objects in nodes
  clusterExport(cl, c("dt.zip", "periods", "states", "instub_mw", "instub_lodes", "outstub"), 
                    env = environment())                                # Load local environment objects in nodes

  # Build exp MW data
  dts.exp <- parLapply(cl, states, function(st) {
      
    dt.st <- assemble_expmw_state(st, periods, "actual_mw", dt.zip, instub_lodes)
    return(dt.st)
  })
  
  dt.exp_mw <- rbindlist(dts.exp)
  
  dts.exp_wg_mean <- parLapply(cl, states, function(st) {
     
    dt.st <- assemble_expmw_state(st, periods, "actual_mw_wg_mean", dt.zip, instub_lodes)
    return(dt.st)
  })
  stopCluster(cl)
  
  dt.exp_mw_wg_mean <- rbindlist(dts.exp)
  exp_mw_vars <- c("exp_mw_tot", "exp_mw_young", "exp_mw_lowinc")
  setnames(dt.exp_mw_wg_mean, old = exp_mw_vars,
                              new = paste0(exp_mw_vars, "_wg_mean"))
  
  # Put data together and format
  dt.exp_mw <- merge(dt.exp_mw, dt.exp_mw_wg_mean, by = c("zipcode", "year_month"))
  dt.exp_mw[, year_month := as.yearmon(year_month)]
  dt.exp_mw[, month := format(dt.exp_mw$year_month)]
  dt.exp_mw[, year  := format(dt.exp_mw$year_month, "%Y")]
  
  # Save data
  save_data(dt.exp_mw, key = c("zipcode", "year", "month"),
            filename = file.path(outstub, "zip_experienced_mw.csv"),
            logfile  = log_file)
  
  save_data(dt.exp_mw, key = c("zipcode", "year", "month"),
            filename = file.path(outstub, "zip_experienced_mw.dta"),
            nolog    = TRUE)
}

assemble_expmw_state <- function(x, periods, mw_var, dt.zip, instub_lodes) {
   
  dt.od <- load_od_matrix(x, instub_lodes)
   
  # Computes share of treated and experienced MW for every period
  dts.period <- lapply(periods, function(y, this_st = dt.od, zip = dt.zip) {
     
     dt.this_date <- zip[year_month == y, ]       # Select given date
     dt.this_date[, w_zipcode := zipcode]         # Create matching variable
     
     vars_to_keep <- c("w_zipcode", mw_var, "year_month")
     dt.this_date <- dt.this_date[, ..vars_to_keep]
     
     dt.this_date <- dt.this_date[dt.od, on = 'w_zipcode'] # Paste MW to every residence(h)-workplace(w)
                                                           #  combination in 'dt.od'
     dt.this_date <- dt.this_date[!is.na(year_month),]     # Drop missings (zipcodes not showing up in mw data)
   
     dt.this_date[, c("sh_tot", "sh_young", "sh_lowinc") := 
                     .((totjob / h_totjob), 
                       (job_young / h_job_young), 
                       (job_lowinc / h_job_lowinc))] #compute share of job for each destination
     
     dt.this_date <- dt.this_date[, 
         .(exp_mw_tot    = sum(get(mw_var)*sh_tot,    na.rm = T), 
           exp_mw_young  = sum(get(mw_var)*sh_young,  na.rm = T), 
           exp_mw_lowinc = sum(get(mw_var)*sh_lowinc, na.rm = T)), 
      by = c("h_zipcode", "year_month")
    ]
     
    setnames(dt.this_date, old = "h_zipcode", new = "zipcode")
   
    return(dt.this_date)
  })
  
  return(rbindlist(dts.period))
}

load_od_matrix <- function(st, instub) {
   
   od <- fread(file.path(instub, paste0('odzip_', st, '.csv')))
   
   od[, c('h_totjob', 'h_job_young', 'h_job_lowinc') := lapply(.SD, sum, na.rm = T) , 
      .SDcols = c('totjob', 'job_young', 'job_lowinc'), 
      by = 'h_zipcode']
   
   setorder(od, h_zipcode, w_zipcode)
   return(od)
}

main()
