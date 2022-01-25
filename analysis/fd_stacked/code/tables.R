remove(list = ls())


main <- function() {
  instub  <- "../output/"
  outstub <- "../output/"
  
  est <- read.csv(file.path(instub, "estimates_stacked_static.csv"))
  
  txt <- c("<tab:stacked>")
  txt <- c(txt, 
           paste(est[est$model == "exp_mw_on_mw_w6",]$b,
                 est[est$model == "res_only_w6",]$b, 
                 est[est$model == "static_w6" & est$var == "d_ln_mw",]$b, sep = "\t"),
            paste(est[est$model == "exp_mw_on_mw_w6",]$se,
                 est[est$model == "res_only_w6",]$se, 
                 est[est$model == "static_w6" & est$var == "d_ln_mw",]$se, sep = "\t"))
  
  txt <- c(txt, 
           paste(est[est$model == "exp_only_w6",]$b, 
                 est[est$model == "static_w6" & est$var == "d_exp_ln_mw",]$b, sep = "\t"),
            paste(est[est$model == "exp_only_w6",]$se, 
                 est[est$model == "static_w6" & est$var == "d_exp_ln_mw",]$se, sep = "\t"))
  
  txt <- c(txt, paste0(est[est$model == "static_w6" & est$var == "cumsum_from0",]$b))
  txt <- c(txt, paste0(est[est$model == "static_w6" & est$var == "cumsum_from0",]$se))
  txt <- c(txt, paste0(est[est$model == "static_w6" & est$var == "cumsum_from0",]$p_equality))
  
  txt <- c(txt, 
           paste(est[est$model == "exp_mw_on_mw_w6",]$r2,
                 est[est$model == "res_only_w6",]$r2, 
                 est[est$model == "exp_only_w6",]$r2, 
                 est[est$model == "static_w6",]$r2[1], sep = "\t"),
            paste(est[est$model == "exp_mw_on_mw_w6",]$N,
                 est[est$model == "res_only_w6",]$N, 
                 est[est$model == "exp_only_w6",]$N, 
                 est[est$model == "static_w6",]$N[1], sep = "\t"))
  
  fileConn <- file(file.path(outstub, "stacked.txt"))
  writeLines(txt, fileConn)
  close(fileConn)
}

main()
