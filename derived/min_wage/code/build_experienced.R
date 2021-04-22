remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")

paquetes <- c("data.table", "usmap", "zoo")
load_packages(paquetes)

setDTthreads(20)

library(parallel)
n_cores <- 10

main <- function(){
  instub_mw    <- "../../../drive/derived_large/min_wage"
  instub_lodes <- "../../../drive/base_large/lodes"
  outstub      <- "../../../drive/derived_large/min_wage"
  log_file     <- "../output/data_file_manifest.log"
  
  
  for (geo in c("countyfips", "zipcode")) {
    
    if (geo == "countyfips"){
      dt <- fread(file.path(instub_mw, "county_statutory_mw.csv"),
                  colClasses = c("countyfips" = "character"))
    } 
    else{
      dt <- fread(file.path(instub_mw, "zip_statutory_mw.csv"),
                  colClasses = c("zipcode" = "character"))
    }                     
    
    periods <- unique(dt$year_month)
    states  <- fips(c(state.abb, 'DC'))
    
    # Parallel set-up
    cl <- makeCluster(n_cores, type = "PSOCK")   # Create cluster. Use type = "FORK" in Mac
    
    clusterExport(cl, "paquetes")                                         # Load "paquetes" object in nodes
    clusterEvalQ(cl, lapply(paquetes, require, character.only = TRUE))    # Load packages in nodes
    clusterExport(cl, "load_od_matrix", env = .GlobalEnv)                 # Load global environment objects in nodes
    clusterExport(cl, "assemble_expmw_state", env = .GlobalEnv)           # Load global environment objects in nodes
    clusterExport(cl, c("dt", "periods", "states", "instub_mw", "instub_lodes", "outstub", "geo"), 
                      env = environment())                                # Load local environment objects in nodes
  
    # Build exp MW data
    dts.exp <- parLapply(cl, states, function(st) {
        
      dt.st <- assemble_expmw_state(st, periods, "actual_mw", dt, instub_lodes, geo)
      return(dt.st)
    })
    
    dt.exp_mw <- rbindlist(dts.exp)
    
    dts.exp_wg_mean <- parLapply(cl, states, function(st) {
       
      dt.st <- assemble_expmw_state(st, periods, "actual_mw_wg_mean", dt, instub_lodes, geo)
      return(dt.st)
    })
    
    dts.exp_max <- parLapply(cl, states, function(st) {
      
      dt.st <- assemble_expmw_state(st, periods, "actual_mw_max", dt, instub_lodes, geo)
      return(dt.st)
    })
    stopCluster(cl)
    
    dt.exp_mw_wg_mean <- rbindlist(dts.exp)
    exp_mw_vars <- c("exp_mw_tot",    "exp_mw_young",    "exp_mw_lowinc", 
                     "exp_ln_mw_tot", "exp_ln_mw_young", "exp_ln_mw_lowinc")
    setnames(dt.exp_mw_wg_mean, old = exp_mw_vars,
                                new = paste0(exp_mw_vars, "_wg_mean"))
    
    dt.exp_max <- rbindlist(dts.exp_max)
    exp_mw_vars <- c("exp_mw_tot",    "exp_mw_young",    "exp_mw_lowinc", 
                     "exp_ln_mw_tot", "exp_ln_mw_young", "exp_ln_mw_lowinc")
    setnames(dt.exp_max, old = exp_mw_vars,
                         new = paste0(exp_mw_vars, "_max"))
    
    # Put data together and format
    dt.exp_mw <- merge(dt.exp_mw, dt.exp_mw_wg_mean, by = c(geo, "year_month"))
    dt.exp_mw <- merge(dt.exp_mw, dt.exp_max,        by = c(geo, "year_month"))
    
    dt.exp_mw[, year_month := as.yearmon(year_month)]
    dt.exp_mw[, month := as.numeric(format(dt.exp_mw$year_month, "%m"))]
    dt.exp_mw[, year  := as.numeric(format(dt.exp_mw$year_month, "%Y"))]
    
    # Save data
    save_data(dt.exp_mw, key = c(geo, "year", "month"),
              filename = file.path(outstub, sprintf("%s_experienced_mw.csv", geo)),
              logfile  = log_file)
    
    save_data(dt.exp_mw, key = c(geo, "year", "month"),
              filename = file.path(outstub, sprintf("%s_experienced_mw.dta", geo)),
              nolog    = TRUE)
  }
}

assemble_expmw_state <- function(x, periods, mw_var, dt, instub_lodes, .geo) {
  
  if (.geo == "countyfips") {
    .w_var = "w_countyfips"
    .h_var = "h_countyfips"
  }
  else {
    .w_var = "w_zipcode"
    .h_var = "h_zipcode"
  }
  dt.od <- load_od_matrix(x, instub_lodes, .geo, .w_var, .h_var)
  
  # Computes share of treated and experienced MW for every period
  dts.period <- lapply(periods, function(y, this_st = dt.od, dt.geo = dt,
                                         geo = .geo, w_var = .w_var, h_var = .h_var) {
     
     dt.this_date <- dt.geo[year_month == y, ]            # Select given date
     dt.this_date[, c(w_var) := get(geo)]               # Create matching variable
     
     vars_to_keep <- c(w_var, mw_var, "year_month")
     dt.this_date <- dt.this_date[, ..vars_to_keep]
     
     dt.this_date <- dt.this_date[this_st, on = w_var]       # Paste MW to every residence(h)-workplace(w) combination in 'dt.od'
     dt.this_date <- dt.this_date[!is.na(year_month),]       # Drop missings (geo not showing up in mw data)
     
     dt.this_date[, h_totjob     := sum(totjob),     by = h_var]
     dt.this_date[, h_job_young  := sum(job_young),  by = h_var]
     dt.this_date[, h_job_lowinc := sum(job_lowinc), by = h_var]

     dt.this_date[, c("sh_tot", "sh_young", "sh_lowinc") := 
                     .((totjob / h_totjob), 
                       (job_young / h_job_young), 
                       (job_lowinc / h_job_lowinc))] # Compute share of job for each destination
     
     dt.this_date <- dt.this_date[, 
         .(exp_mw_tot       = sum(get(mw_var)*sh_tot,    na.rm = T), 
           exp_mw_young     = sum(get(mw_var)*sh_young,  na.rm = T), 
           exp_mw_lowinc    = sum(get(mw_var)*sh_lowinc, na.rm = T),
           exp_ln_mw_tot    = sum(log(get(mw_var))*sh_tot,    na.rm = T), 
           exp_ln_mw_young  = sum(log(get(mw_var))*sh_young,  na.rm = T), 
           exp_ln_mw_lowinc = sum(log(get(mw_var))*sh_lowinc, na.rm = T)), 
      by = c(h_var, "year_month")
    ]
     
    setnames(dt.this_date, old = h_var, new = geo)
   
    return(dt.this_date)
  })
  
  return(rbindlist(dts.period))
}

load_od_matrix <- function(st, instub, geo, workplace_var, residence_var) {
  
  if (geo == "countyfips") {
    od <- fread(file.path(instub, paste0('odcounty_', st, '.csv')),
                colClasses = c("h_countyfips" = "character",
                               "w_countyfips" = "character"))
  }
  else{
    od <- fread(file.path(instub, paste0('odzip_', st, '.csv')), 
                colClasses = c("h_zipcode" = "character",
                               "w_zipcode" = "character"))
  }
  
  od[, c('h_totjob', 'h_job_young', 'h_job_lowinc') := lapply(.SD, sum, na.rm = T) , 
    .SDcols = c('totjob', 'job_young', 'job_lowinc'), 
    by = residence_var]
  
  setorderv(od, c(workplace_var, residence_var))
  return(od)
}

main()
