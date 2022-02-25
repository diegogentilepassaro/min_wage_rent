remove(list = ls())

source("../../../lib/R/save_data.R")
source("add_missing_state_years.R")

paquetes <- c("data.table", "zoo")
lapply(paquetes, require, character.only = TRUE)

library(parallel)
n_cores <- 16

main <- function(paquetes, n_cores){
  in_mw    <- "../../../drive/derived_large/min_wage_panels"
  in_lodes <- "../../../drive/base_large/lodes_od"
  outstub  <- "../../../drive/derived_large/min_wage_measures"
  log_file <- "../output/data_file_manifest_cfs.log"
  
  od_yy  = 2018
  geo    = "zipcode"
  .w_var = "w_zipcode"
  .r_var = "r_zipcode"

  dt <- fread(file.path(in_mw, "zipcode_cfs.csv"),
                  colClasses = c(zipcode = "character"))
  dt[, year_month := as.yearmon(paste0(year, "-", month))]
  
  periods <- unique(dt$year_month)
  
  od_files <- list.files(file.path(in_lodes, od_yy), 
                         pattern = sprintf("odzip*"),
                         full.names = T)
  od_files <- add_missing_state_years(od_files, in_lodes, geo, od_yy)

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

  # Parallel set-up
  cl <- makeCluster(n_cores, type = "PSOCK")   # Create cluster. Use type = "FORK" in Mac
      
  clusterExport(cl, "paquetes")                                         # Load "paquetes" object in nodes
  clusterEvalQ(cl, lapply(paquetes, require, character.only = TRUE))    # Load packages in nodes
  clusterExport(cl, "compute_wkp_mw_ym", env = .GlobalEnv)              # Load global environment objects in nodes
  clusterExport(cl, c("dt", "periods", "dt_od", "geo", "jobs_vars"), 
                env = environment())                                    # Load local environment objects in nodes
  
  # Build wkp MW data
  dt.wkp_mw_10pc <- rbindlist(
    parLapply(cl, periods, function(ym) {
      compute_wkp_mw_ym(ym, dt_od, dt, "statutory_mw_cf_10pc", geo, .w_var, .r_var)
    })
  )
  dt.wkp_mw_10pc[, counterfactual := "fed_10pc"]
  
  dt.wkp_mw_9usd <- rbindlist(
    parLapply(cl, periods, function(ym) {
      compute_wkp_mw_ym(ym, dt_od, dt, "statutory_mw_cf_9usd", geo, .w_var, .r_var)
    })
  )
  dt.wkp_mw_9usd[, counterfactual := "fed_9usd"]
  
  dt.wkp_mw_15usd <- rbindlist(
    parLapply(cl, periods, function(ym) {
      compute_wkp_mw_ym(ym, dt_od, dt, "statutory_mw_cf_15usd", geo, .w_var, .r_var)
    })
  )
  dt.wkp_mw_15usd[, counterfactual := "fed_15usd"]
  
  stopCluster(cl)
  
  # Put data together and format
  dt.wkp_mw <- rbindlist(list(dt.wkp_mw_10pc, dt.wkp_mw_9usd, dt.wkp_mw_15usd))
  
  dt.wkp_mw[, month := as.numeric(format(dt.wkp_mw$year_month, "%m"))]
  dt.wkp_mw[, year  := as.numeric(format(dt.wkp_mw$year_month, "%Y"))]
    
  # Save data
  save_data(dt.wkp_mw, key = c(geo, "year", "month", "counterfactual"),
            filename = file.path(outstub, "zipcode_wkp_mw_cfs.dta"),
            logfile  = log_file)
  fwrite(dt.wkp_mw, 
         file = file.path(outstub, "zipcode_wkp_mw_cfs.csv"))
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

compute_wkp_mw_ym <- function(ym, odm, dt_geo, mw_var, .geo, w_var, r_var) {
          
  dt_ym <- dt_geo[year_month == ym, ]             # Select given date
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
                 by = c(r_var, "year_month")]

  setnames(dt_ym, old = r_var, new = .geo)

  return(dt_ym)
}

main(paquetes, n_cores)
