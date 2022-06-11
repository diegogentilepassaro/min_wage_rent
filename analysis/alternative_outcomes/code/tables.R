remove(list = ls())

library(data.table)

main <- function() {
  instub <- "../output"
  outstub <- "../output/"
  
  est <- fread(file.path(instub, "estimates_static.csv"))
  est <- est[var != "cumsum_from0"]
  
  models <- c("sh_residents_accomm_food", "sh_workers_accomm_food", 
              "sh_residents_underHS", "sh_workers_underHS")
  
  txt <- c("<tab:share_migration>")
  
  txt <- c(txt,
           get_estimates(est, models, 'mw_wkp_tot_15_avg', 'b'), 
           get_estimates(est, models, 'mw_wkp_tot_15_avg', 'se'))
  
  txt <- c(txt,
           get_estimates(est, models, 'mw_res_avg', 'b'), 
           get_estimates(est, models, 'mw_res_avg', 'se'))
  
  txt <- c(txt, 
           get_estimates(est, models, 'mw_res_avg', 'r2'), 
           get_estimates(est, models, 'mw_res_avg', 'N'))
  
  fileConn <- file(file.path(outstub, "share_migration.txt"))
  writeLines(txt, fileConn)
  close(fileConn)
  
  
  models <- c("tot_res_accomm_food", "tot_wkp_accomm_food", 
              "tot_res_underHS",     "tot_wkp_underHS")
  
  txt <- c("<tab:total_migration>")
  
  txt <- c(txt,
           get_estimates(est, models, 'mw_wkp_tot_15_avg', 'b'), 
           get_estimates(est, models, 'mw_wkp_tot_15_avg', 'se'))
  
  txt <- c(txt,
           get_estimates(est, models, 'mw_res_avg', 'b'), 
           get_estimates(est, models, 'mw_res_avg', 'se'))
  
  txt <- c(txt, 
           get_estimates(est, models, 'mw_res_avg', 'r2'), 
           get_estimates(est, models, 'mw_res_avg', 'N'))
  
  fileConn <- file(file.path(outstub, "total_migration.txt"))
  writeLines(txt, fileConn)
  close(fileConn)
}

get_estimates <- function(data, models, variable, value) {
  txt <- paste(lapply(models, \(x) data[model == x & var == variable, get(value)]), collapse = "\t")
  return(txt)
}

main()
