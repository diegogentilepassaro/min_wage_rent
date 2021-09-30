remove(list = ls())

source("../../../lib/R/save_data.R")

paquetes <- c("data.table", "zoo")
lapply(paquetes, require, character.only = TRUE)

library(parallel)
n_cores <- 10

main <- function(paquetes, n_cores){
  in_mw    <- "../../../drive/derived_large/min_wage"
  in_lodes <- "../../../drive/base_large/lodes_od"
  outstub  <- "../../../drive/derived_large/min_wage"
  log_file <- "../output/data_file_manifest_cfs.log"
  
  od_yy = 2018
  geo = "zipcode"

  dt <- fread(file.path(in_mw, "zipcode_cfs.csv"),
                  colClasses = c("zipcode" = "character"))
  dt[, year_month := as.yearmon(paste0(year, "-", month))]
    
  periods <- unique(dt$year_month)
  
  od_files <- list.files(file.path(in_lodes, od_yy), 
                         pattern = sprintf("odzip*"),
                         full.names = T) |>
                add_missing_state_years(in_lodes, geo, od_yy)
  
  # Parallel set-up
  cl <- makeCluster(n_cores, type = "PSOCK")   # Create cluster. Use type = "FORK" in Mac
      
  clusterExport(cl, "paquetes")                                         # Load "paquetes" object in nodes
  clusterEvalQ(cl, lapply(paquetes, require, character.only = TRUE))    # Load packages in nodes
  clusterExport(cl, "load_od_matrix", env = .GlobalEnv)                 # Load global environment objects in nodes
  clusterExport(cl, "assemble_expmw_state", env = .GlobalEnv)           # Load global environment objects in nodes
  clusterExport(cl, c("dt", "periods", "in_mw", "in_lodes", "geo", "outstub"), 
                env = environment())                                    # Load local environment objects in nodes
  
  # Build exp MW data
  dt.exp_mw_10pc <- rbindlist(
    parLapply(cl, od_files, function(ff) {
      
      dt.st <- assemble_expmw_state(ff, yy, periods, "actual_mw_cf_10pc", dt, in_lodes, geo)
      return(dt.st)
    })
  )
  dt.exp_mw_10pc[, counterfactual := "fed_10pc"]
  
  dt.exp_mw_9usd <- rbindlist(
    parLapply(cl, od_files, function(ff) {
      
      dt.st <- assemble_expmw_state(ff, yy, periods, "actual_mw_cf_9usd", dt, in_lodes, geo)
      return(dt.st)
    })
  )
  dt.exp_mw_9usd[, counterfactual := "fed_9usd"]
  
  dt.exp_mw_15usd <- rbindlist(
    parLapply(cl, od_files, function(ff) {
      
      dt.st <- assemble_expmw_state(ff, yy, periods, "actual_mw_cf_15usd", dt, in_lodes, geo)
      return(dt.st)
    })
  )
  dt.exp_mw_15usd[, counterfactual := "fed_15usd"]
  
  stopCluster(cl)
  
  # Put data together and format
  dt.exp_mw <- rbindlist(list(dt.exp_mw_10pc, dt.exp_mw_9usd, dt.exp_mw_15usd))
  
  dt.exp_mw[, month := as.numeric(format(dt.exp_mw$year_month, "%m"))]
  dt.exp_mw[, year  := as.numeric(format(dt.exp_mw$year_month, "%Y"))]
  
  # Drop duplicate in zipcode 75501
  dt.rogue  <- dt.exp_mw[zipcode == "75501" & exp_ln_mw_tot > 0]
  dt.exp_mw <- rbindlist(list(dt.exp_mw[zipcode != "75501"], dt.rogue))
  
  # Save data
  save_data(dt.exp_mw, key = c(geo, "year", "month", "counterfactual"),
            filename = file.path(outstub, "zipcode_experienced_mw_cfs.csv"),
            logfile  = log_file)
  save_data(dt.exp_mw, key = c(geo, "year", "month", "counterfactual"),
            filename = file.path(outstub, "zipcode_experienced_mw_cfs.dta"),
            nolog    = TRUE)
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
  
  dt.od     <- load_od_matrix(ff, .geo, .w_var, .r_var)
  jobs_vars <- names(dt.od)[grepl("jobs", names(dt.od))]
  
  # Computes share of treated and experienced MW for every period
  dts.period <- lapply(periods, function(ym, od.st = dt.od, dt.geo = dt,
                                         geo = .geo, w_var = .w_var, h_var = .r_var) {
     
     dt.ym <- dt.geo[year_month == ym, ]            # Select given date
     dt.ym[, c(w_var) := get(geo)]                  # Create matching variable
     
     vars_to_keep <- c(w_var, mw_var, "year_month")
     dt.ym <- dt.ym[, ..vars_to_keep]
     
     dt.ym <- dt.ym[od.st, on = w_var]       # Paste MW to every residence(h)-workplace(w) combination in 'od.st'
     dt.ym <- dt.ym[!is.na(year_month),]     # Drop missings (geo not showing up in mw data)
   
     dt.ym <- dt.ym[,
         .(exp_ln_mw_tot             = sum(log(get(mw_var))*sh_tot,            na.rm = T),
           exp_ln_mw_age_under29     = sum(log(get(mw_var))*sh_age_under29,    na.rm = T),
           exp_ln_mw_age_30to54      = sum(log(get(mw_var))*sh_age_30to54,     na.rm = T),
           exp_ln_mw_age_above55     = sum(log(get(mw_var))*sh_age_above55,    na.rm = T),
           exp_ln_mw_earn_under1250  = sum(log(get(mw_var))*sh_earn_under1250, na.rm = T),
           exp_ln_mw_earn_1250_3333  = sum(log(get(mw_var))*sh_earn_1250_3333, na.rm = T),
           exp_ln_mw_earn_above3333  = sum(log(get(mw_var))*sh_earn_above3333, na.rm = T),
           exp_ln_mw_goods_prod      = sum(log(get(mw_var))*sh_goods_producing, na.rm = T),
           exp_ln_mw_trad_tran_util  = sum(log(get(mw_var))*sh_trade_transp_util, na.rm = T),
           exp_ln_mw_other_serv_ind  = sum(log(get(mw_var))*sh_other_service_industry, na.rm = T)),
      .SDcols = jobs_vars,
      by = c(h_var, "year_month")
    ]
     
    setnames(dt.ym, old = h_var, new = geo)
   
    return(dt.ym)
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
