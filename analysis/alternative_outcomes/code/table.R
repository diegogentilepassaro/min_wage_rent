remove(list = ls())

library(data.table)

main <- function() {
  instub <- "../output"
  outstub <- "../output/"
  
  est <- fread(file.path(instub, "estimates_static.csv"))
  est_var <- est[var != "cumsum_from0"]
  est_var <- est_var[at == 0]
  
  txt <- c("<tab:share_migration>")
  
  txt <- c(txt, 
           paste(est_var[model == "sh_workers_under1250"   & var == "mw_wkp_tot_15_avg"]$b, 
                 est_var[model == "sh_residents_underHS"   & var == "mw_wkp_tot_15_avg"]$b,
                 est_var[model == "sh_workers_accomm_food" & var == "mw_wkp_tot_15_avg"]$b, sep = "\t"), 
           paste(est_var[model == "sh_workers_under1250"   & var == "mw_wkp_tot_15_avg"]$se, 
                 est_var[model == "sh_residents_underHS"   & var == "mw_wkp_tot_15_avg"]$se,
                 est_var[model == "sh_workers_accomm_food" & var == "mw_wkp_tot_15_avg"]$se, sep = "\t"))
  
  txt <- c(txt, 
           paste(est_var[model == "sh_workers_under1250"   & var == "mw_res_avg"]$b, 
                 est_var[model == "sh_residents_underHS"   & var == "mw_res_avg"]$b,
                 est_var[model == "sh_workers_accomm_food" & var == "mw_res_avg"]$b, sep = "\t"), 
           paste(est_var[model == "sh_workers_under1250"   & var == "mw_res_avg"]$se, 
                 est_var[model == "sh_residents_underHS"   & var == "mw_res_avg"]$se,
                 est_var[model == "sh_workers_accomm_food" & var == "mw_res_avg"]$se, sep = "\t"))
  
  txt <- c(txt, 
           paste(est_var[model == "sh_workers_under1250"   & var == "mw_res_avg"]$r2, 
                 est_var[model == "sh_residents_underHS"   & var == "mw_res_avg"]$r2,
                 est_var[model == "sh_workers_accomm_food" & var == "mw_res_avg"]$r2, sep = "\t"), 
           paste(est_var[model == "sh_workers_under1250"   & var == "mw_res_avg"]$N, 
                 est_var[model == "sh_residents_underHS"   & var == "mw_res_avg"]$N,
                 est_var[model == "sh_workers_accomm_food" & var == "mw_res_avg"]$N, sep = "\t"))
  
  fileConn <- file(file.path(outstub, "share_migration.txt"))
  writeLines(txt, fileConn)
  close(fileConn)
}

main()
