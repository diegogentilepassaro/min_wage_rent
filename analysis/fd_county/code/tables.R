remove(list = ls())


main <- function() {
  
  instub  <- "../output/"
  outstub <- "../output/"
  
  est <- read.csv(file.path(instub, "estimates_static.csv"))
  est_var <- est[est$var != "cumsum_from0", ]
  
  
  txt <- c("<tab:static>")
  txt <- c(txt, 
           paste(est_var[est_var$model == "mw_wkp_on_res_mw",]$b,
                 est_var[est_var$model == "static_mw_res",]$b, 
                 est_var[est_var$model == "static_both" & est_var$var == "mw_res",]$b, sep = "\t"),
           paste(est_var[est_var$model == "mw_wkp_on_res_mw",]$se,
                 est_var[est_var$model == "static_mw_res",]$se, 
                 est_var[est_var$model == "static_both" & est_var$var == "mw_res",]$se, sep = "\t"))
  
  txt <- c(txt, 
           paste(est_var[est_var$model == "static_mw_wkp",]$b, 
                 est_var[est_var$model == "static_both" & est_var$var == "mw_wkp_tot_17",]$b, sep = "\t"),
           paste(est_var[est_var$model == "static_mw_wkp",]$se, 
                 est_var[est_var$model == "static_both" & est_var$var == "mw_wkp_tot_17",]$se, sep = "\t"))
  
  txt <- c(txt, paste0(est[est$model == "static_both" & est$var == "cumsum_from0",]$b))
  txt <- c(txt, paste0(est[est$model == "static_both" & est$var == "cumsum_from0",]$se))
  txt <- c(txt, paste0(est[est$model == "static_both" & est$var == "cumsum_from0",]$p_equality))
  
  txt <- c(txt, 
           paste(est_var[est_var$model == "mw_wkp_on_res_mw",]$r2,
                 est_var[est_var$model == "static_mw_res",]$r2, 
                 est_var[est_var$model == "static_mw_wkp",]$r2, 
                 est_var[est_var$model == "static_both",]$r2[1], sep = "\t"),
           paste(est_var[est_var$model == "mw_wkp_on_res_mw",]$N,
                 est_var[est_var$model == "static_mw_res",]$N, 
                 est_var[est_var$model == "static_mw_wkp",]$N, 
                 est_var[est_var$model == "static_both",]$N[1], sep = "\t"))
  
  fileConn <- file(file.path(outstub, "static.txt"))
  writeLines(txt, fileConn)
  close(fileConn)
}

main()
