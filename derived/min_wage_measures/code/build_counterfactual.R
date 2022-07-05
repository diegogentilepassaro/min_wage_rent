remove(list = ls())
library(data.table)
library(zoo)

source("../../../lib/R/save_data.R")
source("add_missing_state_years.R")

main <- function(){
  in_mw    <- "../../../drive/derived_large/min_wage_panels"
  in_lodes <- "../../../drive/base_large/lodes_od"
  outstub  <- "../../../drive/derived_large/min_wage_measures"
  log_file <- "../output/data_file_manifest_cfs.log"
  
  od_yy = 2017
  geo   = "zipcode"
  w_var = paste0("w_", geo)
  r_var = paste0("r_", geo)
  cf_stub <- c("10pc", "9usd", "15usd", "chi14")
  
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
    lapply(od_files, function(ff) load_od_matrix(ff, geo, w_var, r_var))
  )
  
  jobs_vars <- names(dt_od)[grepl("jobs", names(dt_od))]

  dt_od     <- clean_od_matrix(dt_od, geo, w_var, r_var, jobs_vars)
  
  jobs_vars <- names(dt_od)[grepl("sh", names(dt_od))]

  # Build wkp MW data
  dt.cf <- data.table()
  for (stub in cf_stub) {
    dt_stub <- rbindlist(lapply(periods, function(ym) {
                           compute_wkp_mw_ym(ym, dt_od, copy(dt), stub, jobs_vars,
                                             geo, w_var, r_var)
                         }))
    dt_stub <- add_statutory_mw(dt_stub, dt, stub)
    
    dt.cf <- rbindlist(list(dt.cf, dt_stub))
  }
  
  # Add variables
  dt.cf[, month := as.numeric(format(dt.cf$year_month, "%m"))]
  dt.cf[, year  := as.numeric(format(dt.cf$year_month, "%Y"))]
  dt.cf[, year_month := NULL]
  
  dt.cf[, mw_res := log(statutory_mw)]
  
  # Save data
  save_data(dt.cf, key = c(geo, "year", "month", "counterfactual"),
            filename = file.path(outstub, "zipcode_wkp_mw_cfs.dta"),
            logfile  = log_file)
  fwrite(dt.cf,
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

clean_od_matrix <- function(dt_od, geo, w_var, r_var, jobs_vars) {
  
  # Drop flows with missing zip code name which correspond to non-assigned blocks
  dt_od <- dt_od[get(paste0("r_", geo)) != ""]
  dt_od <- dt_od[get(paste0("w_", geo)) != ""]
  
  # Group zip codes that appear in multiple states
  dt_od <- dt_od[, lapply(.SD, sum),
                 by = c(w_var, r_var),
                 .SDcols = jobs_vars]
  
  # Sum all jobs originating in residence zip codes
  dt_od[, c(paste0("r_", jobs_vars)) := lapply(.SD, sum, na.rm = T) ,
        .SDcols = jobs_vars, 
        by = c(r_var)]
  
  # Compute share of job to each destination for each jobs_var
  for (var in jobs_vars) {
    dt_od[, c(gsub("jobs_", "sh_", var)) := get(var)/get(paste0("r_", var))]
    dt_od[, c(var, paste0("r_", var))    := NULL]
  }
  
  return(dt_od)
}

compute_wkp_mw_ym <- function(ym, odm, dt_geo, stub, jobs_vars,
                              .geo, .w_var, .r_var) {
  
  mw_var <- paste0("statutory_mw_cf_", stub)      
  
  dt_ym <- dt_geo[year_month == ym, ]             # Select given date
  dt_ym[, c(.w_var) := get(.geo)]                 # Create matching variable

  vars_to_keep <- c(.w_var, mw_var, "year_month")
  dt_ym <- dt_ym[, ..vars_to_keep]

  dt_ym <- dt_ym[odm, on = .w_var]        # Paste MW to every residence(h)-workplace(w) combination in 'dt_od'
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
                 by = c(.r_var, "year_month")]

  setnames(dt_ym, old = .r_var, new = .geo)

  return(dt_ym)
}

add_statutory_mw <- function(dt.wkp, dt, stub) {
  
  statutory_mw_var <- paste0("statutory_mw_cf_", stub)
  keep_vars <- c("zipcode", "year_month", statutory_mw_var)
  
  dt.res <- dt[, ..keep_vars]
  setnames(dt.res, old = statutory_mw_var, new = "statutory_mw")
  
  dt.wkp <- merge(dt.wkp, dt.res,
                  by = c("zipcode", "year_month"))
  
  if (stub == "chi14") {
    dt.wkp[, counterfactual := "chi14"]
  } else {
    dt.wkp[, counterfactual := paste0("fed_", stub)]
  }
  
  return(dt.wkp)
}


main()
