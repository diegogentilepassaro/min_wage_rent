remove(list = ls())

library(data.table)

main <- function() {
  instub <- "../output"
  outstub <- "../output/"
  
  est <- fread(file.path(instub, "estimates_autocorrelation.csv"))
  est_var <- est[var != "cumsum_from0"]
  
  txt <- c("<tab:static>")
  
  txt <- c(txt, 
           paste(est_var[model == "levels_model" & var == "mw_res"]$b, 
                 est_var[model == "baseline_model" & var == "mw_res"]$b, sep = "\t"), 
           paste(est_var[model == "levels_model" & var == "mw_res"]$se, 
                 est_var[model == "baseline_model" & var == "mw_res"]$se, sep = "\t"))
  
  txt <- c(txt, 
           paste(est_var[model == "levels_model" & var == "mw_wkp_tot_17"]$b, 
                 est_var[model == "baseline_model" & var == "mw_wkp_tot_17"]$b, sep = "\t"), 
           paste(est_var[model == "levels_model" & var == "mw_wkp_tot_17"]$se,
                 est_var[model == "baseline_model" & var == "mw_wkp_tot_17"]$se, sep = "\t"))
  
  txt <- c(txt, paste(format(round(est_var[model == "baseline_model" & var == "mw_res"]$p_val),nsmall=3)))
  
  txt <- c(txt, paste(est_var[model == "levels_model" & var == "mw_res"]$N, 
                      est_var[model == "baseline_model" & var == "mw_res"]$N, sep = "\t"))
  
  fileConn <- file(file.path(outstub, "autocorrelation.txt"))
  writeLines(txt, fileConn)
  close(fileConn)
}

main()