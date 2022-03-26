remove(list = ls())

source("../../../lib/R/save_data.R")
source("add_missing_state_years.R")

paquetes <- c("data.table", "zoo")
lapply(paquetes, require, character.only = TRUE) -> l

library(parallel)
n_cores <- 18

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
    
    periods <- unique(dt$year_month)[1:5]
    
    for (yy in c(2017)) {
      
      print(sprintf("Computing workplace MW for %s using shares from year %s.",
                    geo, yy))
      
      # Preliminaries
      mw_var = "statutory_mw"
      
      if (geo == "countyfips") {
        w_var = "w_countyfips"
        r_var = "r_countyfips"
      } else {
        w_var = "w_zipcode"
        r_var = "r_zipcode"
      }
      
      dt_od <- load_od_matrix(in_lodes, yy,
                              geo, w_var, r_var)
      
      # Compute commuting shares
      geos_valid_stat_mw <- unique(dt[year == 2019 & month == 1
                                      & !is.na(get(mw_var))][[geo]])
      
      dt_od     <- compute_shares(dt_od, geos_valid_stat_mw, w_var, r_var)
      
      jobs_vars <- names(dt_od)[grepl("sh", names(dt_od))]
      
      # Parallel set-up
      cl <- makeCluster(n_cores, type = "PSOCK")   # Create cluster. Use type = "FORK" in Mac
      
      clusterExport(cl, "paquetes")                                          # Load "paquetes" object in nodes
      clusterEvalQ(cl, lapply(paquetes, require, character.only = TRUE))     # Load packages in nodes
      clusterExport(cl, "compute_wkp_mw_ym", env = .GlobalEnv)               # Load global environment objects in nodes
      clusterExport(cl, c("dt", "periods", "in_mw", "in_lodes", "outstub", 
                          "geo", "w_var", "r_var", "dt_od", "mw_var", "jobs_vars"), 
                    env = environment())                                     # Load local environment objects in nodes
      
      # Build wkp MW for each period
      dt_mw <- parLapply(cl, periods, function(ym) {
        compute_wkp_mw_ym(ym, odm = dt_od, dt_geo = dt,
                         .geo = geo, .w_var = w_var, .r_var = r_var)
      })
      stopCluster(cl)
      
      dt_mw <- rbindlist(dt_mw)
      
      # When all job flows are zero the wkp MW is returned to be zero
      # We NA those cases
      for (var in names(dt_mw)[grepl("mw_wkp", names(dt_mw))]) {
        stopifnot(
          all.equal(log(7.25), dt_mw[get(var) > 0, min(get(var))],
                    tolerance = 0.00001)
        )
        dt_mw[get(var) == 0, c(var) := NA_real_]
      }
      
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

load_od_matrix <- function(instub, yy, .geo, .w_var, .r_var) {
  
  od_files <- list.files(file.path(instub, yy), 
                         pattern = sprintf("od%s*", substr(.geo, 1, 3)),
                         full.names = T)
  od_files <- add_missing_state_years(od_files, instub, .geo, yy)
  
  dt_od <- rbindlist(
      lapply(od_files, function(ff) {
        return(fread(file.path(ff),
                     colClasses = list(character = c(.w_var, .r_var))))
      })
    )
  
  # Drop flows with missing zip code name which correspond to non-assigned blocks
  dt_od <- dt_od[get(.w_var) != ""]
  dt_od <- dt_od[get(.r_var) != ""]
  
  # Group zip codes that appear in multiple states
  jobs_vars <- names(dt_od)[grepl("jobs", names(dt_od))]
  
  dt_od <- dt_od[, lapply(.SD, sum),
                 by = c(.w_var, .r_var),
                 .SDcols = jobs_vars]
  
  setkeyv(dt_od, c(.r_var, .w_var))
  
  return(dt_od)
}

compute_shares <- function(dt_od, geos_valid_stat_mw, 
                           .w_var, .r_var) {
  
  jobs_vars <- names(dt_od)[grepl("jobs", names(dt_od))]
  
  # Keep residences and workplaces that have a valid MW
  dt_od <- dt_od[get(.w_var) %in% geos_valid_stat_mw]
  dt_od <- dt_od[get(.r_var) %in% geos_valid_stat_mw]
  
  # Sum all jobs originating in residence zip codes
  dt_od[, c(paste0("r_", jobs_vars)) := lapply(.SD, sum, na.rm = T),
        .SDcols = jobs_vars, 
        by = c(.r_var)]
  
  # Compute share of job to each destination for each jobs_var
  for (var in jobs_vars) {
    dt_od[, c(gsub("jobs_", "sh_", var)) := get(var)/get(paste0("r_", var))]
    dt_od[, c(var, paste0("r_", var))    := NULL]
  }
  
  return(dt_od)
}

compute_wkp_mw_ym <- function(ym, odm, dt_geo, .geo, .w_var, .r_var) {
          
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


main(paquetes, n_cores)
