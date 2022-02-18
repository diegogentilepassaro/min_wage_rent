remove(list = ls())

source("../../../lib/R/save_data.R")

paquetes <- c("data.table", "zoo")
lapply(paquetes, require, character.only = TRUE)

library(parallel)
n_cores <- 16

main <- function(paquetes, n_cores){
  in_mw    <- "../../../drive/derived_large/min_wage"
  in_lodes <- "../../../drive/base_large/lodes_od"
  outstub  <- "../../../drive/derived_large/min_wage"
  log_file <- "../output/data_file_manifest.log"
  
  for (geo in c("countyfips", "zipcode")) {
    
    if (geo == "countyfips"){
      dt <- fread(file.path(in_mw, "county_statutory_mw.csv"),
                  colClasses = c(countyfips = "character"))
    } else{
      dt <- fread(file.path(in_mw, "zip_statutory_mw.csv"),
                  colClasses = c(zipcode = "character"))
    }
    dt[, year_month := as.yearmon(paste0(year, "-", month))]
    
    periods <- unique(dt$year_month)
    
    for (yy in 2009:2018) {
      
      od_files <- list.files(file.path(in_lodes, yy), 
                             pattern = sprintf("od%s*", substr(geo, 1, 3)),
                             full.names = T)
      
      od_files <- add_missing_state_years(od_files, in_lodes, geo, yy)
      
      # Parallel set-up
      cl <- makeCluster(n_cores, type = "PSOCK")   # Create cluster. Use type = "FORK" in Mac
      
      clusterExport(cl, "paquetes")                                         # Load "paquetes" object in nodes
      clusterEvalQ(cl, lapply(paquetes, require, character.only = TRUE))    # Load packages in nodes
      clusterExport(cl, "load_od_matrix", env = .GlobalEnv)                 # Load global environment objects in nodes
      clusterExport(cl, "assemble_expmw_state", env = .GlobalEnv)           # Load global environment objects in nodes
      clusterExport(cl, c("dt", "periods", "in_mw", "in_lodes", "outstub", "geo"), 
                    env = environment())                                    # Load local environment objects in nodes
      
      # Build exp MW data
      dt_mw <- parLapply(cl, od_files, function(ff) {
        
        dt_st <- assemble_expmw_state(ff, yy, periods, "actual_mw", dt, in_lodes, geo)
        return(dt_st)
      })
      
      dt_mw <- rbindlist(dt_mw)
      exp_mw_vars <- names(dt_mw)[grepl("exp_ln_mw", names(dt_mw))]
      
      dt_mw_mean <- parLapply(cl, od_files, function(ff) {
        
        dt_st <- assemble_expmw_state(ff, yy, periods, "actual_mw_mean", dt, in_lodes, geo)
        return(dt_st)
      })
      stopCluster(cl)
      
      dt_mw_mean <- rbindlist(dt_mw_mean)
      exp_mw_vars <- names(dt_mw_mean)[grepl("exp_ln_mw", names(dt_mw_mean))]
      setnames(dt_mw_mean, old = exp_mw_vars,
                               new = paste0(exp_mw_vars, "_mean"))
      
      # Put data together and format
      dt_mw <- merge(dt_mw, dt_mw_mean, by = c(geo, "year_month"))
      
      dt_mw[, month := as.numeric(format(dt_mw$year_month, "%m"))]
      dt_mw[, year  := as.numeric(format(dt_mw$year_month, "%Y"))]
      
      # Save data
      save_data(dt_mw, key = c(geo, "year", "month"),
                filename = file.path(outstub, sprintf("%s_experienced_mw_%s.csv", geo, yy)),
                logfile  = log_file)
      save_data(dt_mw, key = c(geo, "year", "month"),
                filename = file.path(outstub, sprintf("%s_experienced_mw_%s.dta", geo, yy)),
                nolog    = TRUE)
    }
  }
}

add_missing_state_years <- function(od_files, instub, geo, yy) {
  
  if (geo == "countyfips") geo <- "county"
  else                     geo <- "zip"
  
  if (yy == 2009) {
    return(c(od_files, sprintf("%s/2010/od%s_11.csv", instub, geo), 
                       sprintf("%s/2011/od%s_25.csv", instub, geo)))
  } else if (yy == 2010) {
    return(c(od_files, sprintf("%s/2011/od%s_25.csv", instub, geo)))
  } else if (yy %in% c(2017, 2018)) {
    return(c(od_files, sprintf("%s/2016/od%s_02.csv", instub, geo)))
  } else {
    return(od_files)
  }
}

assemble_expmw_state <- function(ff, yy, periods, mw_var, dt, in_lodes, .geo) {
  
  if (.geo == "countyfips") {
    .w_var = "w_countyfips"
    .r_var = "r_countyfips"
  }
  else {
    .w_var = "w_zipcode"
    .r_var = "r_zipcode"
  }
  
  dt_od     <- load_od_matrix(ff, .geo, .w_var, .r_var)
  jobs_vars <- names(dt_od)[grepl("jobs", names(dt_od))]
  
  # Computes share of treated and experienced MW for every period
  dts.period <- lapply(periods, function(ym, od.st = dt_od, dt_geo = dt,
                                         geo = .geo, w_var = .w_var, h_var = .r_var) {
     
     dt_ym <- dt_geo[year_month == ym, ]            # Select given date
     dt_ym[, c(w_var) := get(geo)]                  # Create matching variable
     
     vars_to_keep <- c(w_var, mw_var, "year_month")
     dt_ym <- dt_ym[, ..vars_to_keep]
     
     dt_ym <- dt_ym[od.st, on = w_var]       # Paste MW to every residence(h)-workplace(w) combination in 'dt_od'
     dt_ym <- dt_ym[!is.na(year_month),]     # Drop missings (geo not showing up in mw data)
   
     dt_ym <- dt_ym[,
         .(exp_ln_mw_tot             = sum(log(get(mw_var))*sh_tot,              na.rm = T),
           exp_ln_mw_age_under29     = sum(log(get(mw_var))*sh_age_under29,      na.rm = T),
           exp_ln_mw_age_30to54      = sum(log(get(mw_var))*sh_age_30to54,       na.rm = T),
           exp_ln_mw_age_above55     = sum(log(get(mw_var))*sh_age_above55,      na.rm = T),
           exp_ln_mw_earn_under1250  = sum(log(get(mw_var))*sh_earn_under1250,   na.rm = T),
           exp_ln_mw_earn_1250_3333  = sum(log(get(mw_var))*sh_earn_1250_3333,   na.rm = T),
           exp_ln_mw_earn_above3333  = sum(log(get(mw_var))*sh_earn_above3333,   na.rm = T),
           exp_ln_mw_goods_prod      = sum(log(get(mw_var))*sh_goods_producing,  na.rm = T),
           exp_ln_mw_trad_tran_util  = sum(log(get(mw_var))*sh_trade_transp_util, na.rm = T),
           exp_ln_mw_other_serv_ind  = sum(log(get(mw_var))*sh_other_service_industry, na.rm = T)),
      .SDcols = jobs_vars,
      by = c(h_var, "year_month")
    ]
     
    setnames(dt_ym, old = h_var, new = geo)
   
    return(dt_ym)
  })
  
  return(rbindlist(dts.period))
}

load_od_matrix <- function(ff, geo, workplace_var, residence_var) {
  
  if (geo == "countyfips") {
    od <- fread(file.path(ff),
                colClasses = c("r_countyfips" = "character",
                               "w_countyfips" = "character"))
  } else{
    od <- fread(file.path(ff), 
                colClasses = c("r_zipcode" = "character",
                               "w_zipcode" = "character"))
  }
  
  
  jobs_vars <- names(od)[grepl("jobs", names(od))]
  
  # Sum all jobs originitaing in residence zipcode
  od[, c(paste0("r_", jobs_vars)) := lapply(.SD, sum, na.rm = T) , 
    .SDcols = jobs_vars, 
    by = residence_var]
  
  # Compute share of job to each destination for each jobs_var
  for (var in jobs_vars) {
    od[, c(gsub("jobs_", "sh_", var)) := get(var)/get(paste0("r_", var))]
    od[, c(var, paste0("r_", var))    := NULL]
  }
  
  setorderv(od, c(workplace_var, residence_var))
  return(od)
}


main(paquetes, n_cores)
