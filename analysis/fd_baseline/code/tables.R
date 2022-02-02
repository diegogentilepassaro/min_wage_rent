remove(list = ls())


main <- function() {
  
  instub  <- "../output/"
  outstub <- "../output/"
  
  est <- read.csv(file.path(instub, "estimates_static.csv"))
  est_var <- est[est$var != "cumsum_from0", ]
  
  
  txt <- c("<tab:static>")
  txt <- c(txt, 
           paste(est_var[est_var$model == "exp_mw_on_mw",]$b,
                 est_var[est_var$model == "static_statutory",]$b, 
                 est_var[est_var$model == "static_both" & est_var$var == "ln_mw",]$b, sep = "\t"),
            paste(est_var[est_var$model == "exp_mw_on_mw",]$se,
                 est_var[est_var$model == "static_statutory",]$se, 
                 est_var[est_var$model == "static_both" & est_var$var == "ln_mw",]$se, sep = "\t"))
  
  txt <- c(txt, 
           paste(est_var[est_var$model == "static_experienced",]$b, 
                 est_var[est_var$model == "static_both" & est_var$var == "exp_ln_mw_17",]$b, sep = "\t"),
            paste(est_var[est_var$model == "static_experienced",]$se, 
                 est_var[est_var$model == "static_both" & est_var$var == "exp_ln_mw_17",]$se, sep = "\t"))
  
  txt <- c(txt, paste0(est[est$model == "static_both" & est$var == "cumsum_from0",]$b))
  txt <- c(txt, paste0(est[est$model == "static_both" & est$var == "cumsum_from0",]$se))
  txt <- c(txt, paste0(est[est$model == "static_both" & est$var == "cumsum_from0",]$p_equality))
  
  txt <- c(txt, 
           paste(est_var[est_var$model == "exp_mw_on_mw",]$r2,
                 est_var[est_var$model == "static_statutory",]$r2, 
                 est_var[est_var$model == "static_experienced",]$r2, 
                 est_var[est_var$model == "static_both",]$r2[1], sep = "\t"),
            paste(est_var[est_var$model == "exp_mw_on_mw",]$N,
                 est_var[est_var$model == "static_statutory",]$N, 
                 est_var[est_var$model == "static_experienced",]$N, 
                 est_var[est_var$model == "static_both",]$N[1], sep = "\t"))
  
  fileConn <- file(file.path(outstub, "static.txt"))
  writeLines(txt, fileConn)
  close(fileConn)
}




main()
