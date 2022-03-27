remove(list = ls())

main <- function() {
  instub  <- "../temp/"
  outstub <- "../output/"
  
  est <- read.csv(file.path(instub, "estimates.csv"))
  
  txt <- c("<tab:heterogeneity>")
  txt <- c(txt, 
           paste(est[est$model == "static_both"  & est$var == "mw_res",]$b,
                 est[est$model == "heterogeneity"& est$var == "mw_res_high_work_mw" & est$at == 0,]$b, 
                 sep = "\t"))
  txt <- c(txt, 
           paste(est[est$model == "static_both"  & est$var == "mw_res",]$se,
                 est[est$model == "heterogeneity"& est$var == "mw_res_high_work_mw" & est$at == 0,]$se, 
                 sep = "\t"))

  txt <- c(txt, 
           paste(est[est$model == "heterogeneity"& est$var == "mw_res_high_work_mw" & est$at == 1,]$b, 
                 sep = "\t"))
  txt <- c(txt, 
           paste(est[est$model == "heterogeneity"& est$var == "mw_res_high_work_mw" & est$at == 1,]$se, 
                 sep = "\t"))
  
  txt <- c(txt, 
           paste(est[est$model == "static_both"  & est$var == "mw_wkp_tot_17",]$b,
                 est[est$model == "heterogeneity"& est$var == "mw_wkp_high_res_mw" & est$at == 0,]$b, 
                 sep = "\t"))
  txt <- c(txt, 
           paste(est[est$model == "static_both"  & est$var == "mw_wkp_tot_17",]$se,
                 est[est$model == "heterogeneity"& est$var == "mw_wkp_high_res_mw" & est$at == 0,]$se, 
                 sep = "\t"))
  
  txt <- c(txt, 
           paste(est[est$model == "heterogeneity"& est$var == "mw_wkp_high_res_mw" & est$at == 1,]$b, 
                 sep = "\t"))
  txt <- c(txt, 
           paste(est[est$model == "heterogeneity"& est$var == "mw_wkp_high_res_mw" & est$at == 1,]$se, 
                 sep = "\t"))
  
  txt <- c(txt, 
           paste(est[est$model == "static_both"  & est$var == "mw_wkp_tot_17",]$r2,
                 est[est$model == "heterogeneity"& est$var == "mw_wkp_high_res_mw" & est$at == 0,]$r2, 
                 sep = "\t"))
  txt <- c(txt, 
           paste(est[est$model == "static_both"  & est$var == "mw_wkp_tot_17",]$N,
                 est[est$model == "heterogeneity"& est$var == "mw_wkp_high_res_mw" & est$at == 0,]$N, 
                 sep = "\t"))
 
  fileConn <- file(file.path(outstub, "heterogeneity.txt"))
  writeLines(txt, fileConn)
  close(fileConn)
}




main()
