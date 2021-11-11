remove(list = ls())


main <- function() {
  instub  <- "../output/"
  outstub <- "../output/"
  
  est <- read.csv(file.path(instub, "estimates_stacked_static.csv"))
  
  txt <- c("<tab:stacked>")
  txt <- c(txt, 
           paste(est[est$model == "stacked_static_w3" & est$var == "d_ln_mw",]$b,
                 est[est$model == "stacked_static_w6" & est$var == "d_ln_mw",]$b, 
                 est[est$model == "stacked_static_w9" & est$var == "d_ln_mw",]$b, sep = "\t"),
           paste(est[est$model == "stacked_static_w3" & est$var == "d_ln_mw",]$se,
                 est[est$model == "stacked_static_w6" & est$var == "d_ln_mw",]$se, 
                 est[est$model == "stacked_static_w9" & est$var == "d_ln_mw",]$se, sep = "\t"))
  
  txt <- c(txt, 
           paste(est[est$model == "stacked_static_w3" & est$var == "d_exp_ln_mw",]$b,
                 est[est$model == "stacked_static_w6" & est$var == "d_exp_ln_mw",]$b, 
                 est[est$model == "stacked_static_w9" & est$var == "d_exp_ln_mw",]$b, sep = "\t"),
           paste(est[est$model == "stacked_static_w3" & est$var == "d_exp_ln_mw",]$se,
                 est[est$model == "stacked_static_w6" & est$var == "d_exp_ln_mw",]$se, 
                 est[est$model == "stacked_static_w9" & est$var == "d_exp_ln_mw",]$se, sep = "\t"))
  
  txt <- c(txt, 
           paste(est[est$model == "stacked_static_w3" & est$var == "d_ln_mw",]$p_equality,
                 est[est$model == "stacked_static_w6" & est$var == "d_ln_mw",]$p_equality,
                 est[est$model == "stacked_static_w9" & est$var == "d_ln_mw",]$p_equality, sep = "\t"),
           paste(est[est$model == "stacked_static_w3" & est$var == "d_ln_mw",]$r2,
                 est[est$model == "stacked_static_w6" & est$var == "d_ln_mw",]$r2,
                 est[est$model == "stacked_static_w9" & est$var == "d_ln_mw",]$r2, sep = "\t"),
           paste(est[est$model == "stacked_static_w3" & est$var == "d_ln_mw",]$N,
                 est[est$model == "stacked_static_w6" & est$var == "d_ln_mw",]$N,
                 est[est$model == "stacked_static_w9" & est$var == "d_ln_mw",]$N, sep = "\t"))
  
  fileConn <- file(file.path(outstub, "stacked.txt"))
  writeLines(txt, fileConn)
  close(fileConn)
}

main()
