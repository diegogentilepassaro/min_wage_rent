remove(list = ls())

source("../../../lib/R/save_data.R")

paquetes <- c("data.table", "zoo")
lapply(paquetes, require, character.only = TRUE)

library(parallel)
n_cores <- 20

main <- function(paquetes, n_cores){
  in_mw    <- "../../../drive/derived_large/min_wage_panels"
  in_lodes <- "../../../drive/base_large/lodes_od"
  in_geo   <- "../../../drive/base_large/census_block_master"
  outstub  <- "../../../drive/derived_large/min_wage_measures"
  log_file <- "../output/data_file_manifest.log"
  
  for (geo in c("countyfips", "zipcode")) {
    
    dt <- load_statutory(in_mw, geo)
    
    dt[, mw_res := log(statutory_mw)]
    
    keep_vars <- c(geo, "year", "month", "statutory_mw", "mw_res")
    save_data(dt[, ..keep_vars], key = keep_vars[1:3],
              filename = file.path(outstub, sprintf("%s_mw_res.dta", geo)),
              logfile  = log_file)
    fwrite(dt[, ..keep_vars], 
           file = file.path(outstub, sprintf("%s_mw_res.csv", geo)))
    
    dt[, mw_res := NULL]
    
    periods <- unique(dt$year_month)
    
    for (yy in c(2017)) { #2009:2018
      
      # Preliminaries
      mw_var = "statutory_mw"
      
      if (geo == "countyfips") {
        .w_var = "w_countyfips"
        .r_var = "r_countyfips"
      } else {
        .w_var = "w_zipcode"
        .r_var = "r_zipcode"
      }
      od_files <- list.files(file.path(in_lodes, yy), 
                             pattern = sprintf("od%s*", substr(geo, 1, 3)),
                             full.names = T)
      
      od_files <- add_missing_state_years(od_files, in_lodes, geo, yy)
      
      
      # Load od matrix
      dt_od <- rbindlist(
        lapply(od_files, function(ff) load_od_matrix(ff, geo, .w_var, .r_var))
      )
      dt_od <- dt_od[get(paste0("r_", geo)) != ""]           # Why are there zip codes with empty string as name?
      dt_od <- dt_od[get(paste0("w_", geo)) != ""]           # Why are there zip codes with empty string as name?
      
      jobs_vars <- names(dt_od)[grepl("jobs", names(dt_od))]
      
      dt_od <- dt_od[, lapply(.SD, sum),                     # Group zip codes that appear in multiple states
                     by = c(.w_var, .r_var),
                     .SDcols = jobs_vars]
      
      dt_od[, c(paste0("r_", jobs_vars)) := lapply(.SD, sum, na.rm = T) , # Sum all jobs originating in residence zip codes
         .SDcols = jobs_vars, 
         by = c(.r_var)]
      
      for (var in jobs_vars) {                                        # Compute share of job to each destination for each jobs_var
        dt_od[, c(gsub("jobs_", "sh_", var)) := get(var)/get(paste0("r_", var))]
        dt_od[, c(var, paste0("r_", var))    := NULL]
      }
      
      jobs_vars <- names(dt_od)[grepl("sh", names(dt_od))]
      
      setorderv(dt_od, c(.r_var, .w_var))
      
      # Parallel set-up
      cl <- makeCluster(n_cores, type = "PSOCK")   # Create cluster. Use type = "FORK" in Mac
      
      clusterExport(cl, "paquetes")                                         # Load "paquetes" object in nodes
      clusterEvalQ(cl, lapply(paquetes, require, character.only = TRUE))    # Load packages in nodes
      clusterExport(cl, "load_od_matrix", env = .GlobalEnv)                 # Load global environment objects in nodes
      clusterExport(cl, c("dt", "periods", "in_mw", "in_lodes", "outstub", 
                          "geo", ".w_var", ".r_var", "dt_od", "mw_var", "jobs_vars"), 
                    env = environment())                                    # Load local environment objects in nodes
      
      # Build wkp MW for each period
      dt_mw <- parLapply(cl, periods, function(ym, odm = dt_od, dt_geo = dt,
                                               .geo = geo, w_var = .w_var, h_var = .r_var) {
          
          dt_ym <- dt_geo[year_month == ym, ]            # Select given date
          dt_ym[, c(w_var) := get(.geo)]                  # Create matching variable
          
          vars_to_keep <- c(w_var, mw_var, "year_month")
          dt_ym <- dt_ym[, ..vars_to_keep]
          
          dt_ym <- dt_ym[odm, on = w_var]         # Paste MW to every residence(h)-workplace(w) combination in 'dt_od'
          dt_ym <- dt_ym[!is.na(year_month),]     # Drop missings (geo not showing up in mw data)
          
          dt_ym <- dt_ym[,
                         .(mw_wkp_tot            = sum(log(get(mw_var))*sh_tot,               na.rm = T),
                           mw_wkp_age_under29    = sum(log(get(mw_var))*sh_age_under29,       na.rm = T),
                           mw_wkp_age_30to54     = sum(log(get(mw_var))*sh_age_30to54,        na.rm = T),
                           mw_wkp_age_above55    = sum(log(get(mw_var))*sh_age_above55,       na.rm = T),
                           mw_wkp_earn_under1250 = sum(log(get(mw_var))*sh_earn_under1250,    na.rm = T),
                           mw_wkp_earn_1250_3333 = sum(log(get(mw_var))*sh_earn_1250_3333,    na.rm = T),
                           mw_wkp_earn_above3333 = sum(log(get(mw_var))*sh_earn_above3333,    na.rm = T),
                           mw_wkp_goods_prod     = sum(log(get(mw_var))*sh_goods_producing,   na.rm = T),
                           mw_wkp_trad_tran_util = sum(log(get(mw_var))*sh_trade_transp_util, na.rm = T),
                           mw_wkp_other_serv_ind = sum(log(get(mw_var))*sh_other_service_industry, na.rm = T)),
                         .SDcols = jobs_vars,
                         by = c(h_var, "year_month")
          ]
          
          setnames(dt_ym, old = h_var, new = .geo)
          
          return(dt_ym)
        })
      stopCluster(cl)
      
      dt_mw <- rbindlist(dt_mw)
      
      dt_mw[, month := as.numeric(format(dt_mw$year_month, "%m"))]
      dt_mw[, year  := as.numeric(format(dt_mw$year_month, "%Y"))]
      dt_mw[, year_month := NULL]
      
      # Save data
      save_data(dt_mw, key = c(geo, "year", "month"),
                filename = file.path(outstub, sprintf("%s_mw_wkp_%s.dta", geo, yy)),
                logfile  = log_file)
      fwrite(dt_mw, 
             file = file.path(outstub, sprintf("%s_mw_wkp_%s.csv", geo, yy)))
    }
  }
}

load_statutory <- function(instub, geo) {
  
  if (geo == "countyfips"){
    dt <- fread(file.path(instub, "county_statutory_mw.csv"),
                colClasses = c(countyfips = "character"))
  } else {
    dt <- fread(file.path(instub, "zip_statutory_mw.csv"),
                colClasses = c(zipcode = "character"))
  }
  dt[, year_month := as.yearmon(paste0(year, "-", month))]
  
  return(dt)
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


load_od_matrix <- function(ff, geo, workplace_var, residence_var) {
  
  if (geo == "countyfips") {
    od <- fread(file.path(ff),
                colClasses = c("r_countyfips" = "character",
                               "w_countyfips" = "character"))
  } else {
    od <- fread(file.path(ff), 
                colClasses = c("r_zipcode" = "character",
                               "w_zipcode" = "character"))
  }
  
  return(od)
}


main(paquetes, n_cores)
