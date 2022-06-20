remove(list=ls())
library(data.table)
library(fixest)
source("../../../lib/R/save_data.R")

main <- function() {
  instub  <- "../../../drive/derived_large/estimation_samples"
  outstub <- "../../../drive/analysis_large/non_parametric"
  
  if (file.exists("../output/data_file_manifest.log")) {
    file.remove("../output/data_file_manifest.log")
  }
  
  dt_all <- load_data(instub)
  
  dt_all[, any_change_in_cbsa_month := 1*any(d_statutory_mw > 0), 
          by = .(cbsa, year, month)]
  dt_all[, any_change_in_month      := 1*any(d_statutory_mw > 0), 
          by = .(year, month)]
  
  dt_all[, resid_timeFE_ln_rents := resid(feols(ln_rents ~ -1 | year^month, dt_all), na.rm = F)]
  dt_all[, resid_timeFE_mw_res   := resid(feols(mw_res ~ -1   | year^month, dt_all), na.rm = F)]
  dt_all[, resid_timeFE_mw_wkp   := resid(feols(mw_wkp ~ -1   | year^month, dt_all), na.rm = F)]
  
  dt_all[, resid_timeFE_d_ln_rents := resid(feols(d_ln_rents ~ -1 | year^month, dt_all), na.rm = F)]
  dt_all[, resid_timeFE_d_mw_res   := resid(feols(d_mw_res ~ -1   | year^month, dt_all), na.rm = F)]
  dt_all[, resid_timeFE_d_mw_wkp   := resid(feols(d_mw_wkp ~ -1   | year^month, dt_all), na.rm = F)]
  
  for (group_var in paste0("any_change_in_", c("cbsa_month", "month"))) {
    
    dt <- dt_all[get(group_var) == 1]
    dt[, c(group_var) := NULL]
    
    dt <- compute_cuts(dt, c("statutory_mw",   "mw_res",   "mw_wkp",
                             "l_statutory_mw", "l_mw_res", "l_mw_wkp",
                             "d_statutory_mw", "d_mw_res", "d_mw_wkp",
                             "resid_timeFE_mw_res", "resid_timeFE_mw_wkp",
                             "resid_timeFE_d_mw_res", "resid_timeFE_d_mw_wkp"))
    
    save_data(dt, key = c("zipcode", "year", "month"),
              filename = sprintf("%s/data_%s.csv", outstub, group_var),
              logfile  = "../output/data_file_manifest.log")
  }
  
  
  {
  # dt_sample <- data.table()
  # for (yyyy in unique(dt$year)) {
  #   dt_yy <- dt[year == yyyy]
  #   
  #   dt_yy[, relevant_zip := max((month == 1 & !is.na(ln_rents))),   by = .(zipcode)]
  #   dt_yy[, change_jan   := max((month == 1 & d_statutory_mw > 0)), by = .(zipcode)]
  #   dt_yy[, change_jul   := max((month == 7 & d_statutory_mw > 0)), by = .(zipcode)]
  #   dt_yy[, no_change    := 1*(all(d_statutory_mw == 0)),           by = .(zipcode)]
  #   
  #   dt_yy <- dt_yy[relevant_zip == 1
  #                 & (change_jan == 1 | change_jul == 1 | no_change == 1)]
  #   
  #   dt_yy[, relevant_zip := NULL]
  #   
  #   if (yyyy <= 2018) {
  #     dt_yy[, mw_wkp := get(paste0("mw_wkp_tot_", yyyy - 2000))]
  #   } else {
  #     dt_yy[, mw_wkp := mw_wkp_tot_18]
  #   }
  #   dt_yy[, c(paste0("mw_wkp_tot_", 15:18)) := NULL]
  #   
  #   dt_sample <- rbindlist(list(dt_sample, dt_yy))
  # }
  }
}

load_data <- function(instub, min_year = 2015) {
  
  dt <- fread(file.path(instub, "zipcode_months.csv"),
              colClasses = list(character = c("zipcode", "cbsa")))
  
  for (yy in 15:18) {
    dt[year == 2000+yy, mw_wkp := get(paste0("mw_wkp_tot_", yy-1))]
  }
  dt[year > 2018, mw_wkp := mw_wkp_tot_18]
  
  mw_vars <- c("statutory_mw", "mw_res", 
               paste0("mw_wkp_tot_", 14:18), "mw_wkp")
  
  setkey(dt, zipcode, year, month)
  
  dt[, d_ln_rents := ln_rents - shift(ln_rents), by = .(zipcode)]
  for (mw_var in mw_vars) {
    dt[, paste0("d_", mw_var) := get(mw_var) - shift(get(mw_var)),
       by = .(zipcode)]
    dt[, paste0("l_", mw_var) := shift(get(mw_var)),
       by = .(zipcode)]
  }
  
  dt <- dt[year >= min_year & !is.na(ln_rents)]
  
  keep_vars <- c("zipcode", "countyfips", "statefips", "cbsa", 
                 "ln_rents", "d_ln_rents",
                 "year", "month", 
                 mw_vars, paste0("d_", mw_vars), paste0("l_", mw_vars))
  
  return(dt[, ..keep_vars])
}


compute_cuts <- function(dt, vars_to_cut) {
  
  for (var in vars_to_cut) {
    var_rank = paste0(var, "_rank")
    dt[, c(var_rank) := rank(get(var), ties.method = "first")]
    
    dt[, c(paste0(var, "_deciles")) 
                     := cut(get(var_rank), 
                            breaks = quantile(get(var_rank), probs = 0:10/10),
                            labels = 1:10, ordered_result = F,
                            include.lowest = T)]
    
    dt[, c(paste0(var, "_50groups")) 
                    := cut(get(var_rank), 
                            breaks = quantile(get(var_rank), probs = 0:50/50),
                            labels = 1:50, ordered_result = F,
                            include.lowest = T)]
    
    dt[, c(paste0(var, "_100groups")) 
                    := cut(get(var_rank), 
                            breaks = quantile(get(var_rank), probs = 0:100/100),
                            labels = 1:100, ordered_result = F,
                            include.lowest = T)]
    
    dt[, c(var_rank) := NULL]
  }
  
  return(dt)
}

main()
