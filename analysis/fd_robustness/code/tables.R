remove(list = ls())
library(data.table)

main <- function() {
  instub  <- "../output/"
  outstub <- "../output/"
  
  est <- fread(file.path(instub, "estimates_static.csv"))

  txt_static_sample <- c("<tab:static_sample>")
  for (xvar in c("mw_res", "mw_wkp_tot_17")) {
    txt_static_sample <- c(txt_static_sample, 
                            paste(est[model == "baseline"     & var == xvar,]$b,
                                  est[model == "baseline_wgt" & var == xvar,]$b,
                                  est[model == "unbal"        & var == xvar,]$b,
                                  est[model == "unbal_wgt"    & var == xvar,]$b,
                                  est[model == "fullbal"      & var == xvar,]$b,
                                  est[model == "fullbal_wgt"  & var == xvar,]$b,
                                  sep = "\t"))
    txt_static_sample <- c(txt_static_sample, 
                            paste(est[model == "baseline"     & var == xvar,]$se,
                                  est[model == "baseline_wgt" & var == xvar,]$se,
                                  est[model == "unbal"        & var == xvar,]$se,
                                  est[model == "unbal_wgt"    & var == xvar,]$se,
                                  est[model == "fullbal"      & var == xvar,]$se,
                                  est[model == "fullbal_wgt"  & var == xvar,]$se,
                                  sep = "\t"))
  }

  for (stat in c("p_equality", "r2", "N")) {
    txt_static_sample <- c(txt_static_sample, 
                            paste(est[model == "baseline"     & var == "cumsum_from0",][[stat]],
                                  est[model == "baseline_wgt" & var == "cumsum_from0",][[stat]],
                                  est[model == "unbal"        & var == "cumsum_from0",][[stat]],
                                  est[model == "unbal_wgt"    & var == "cumsum_from0",][[stat]],
                                  est[model == "fullbal"      & var == "cumsum_from0",][[stat]],
                                  est[model == "fullbal_wgt"  & var == "cumsum_from0",][[stat]],
                                  sep = "\t"))
  }

  fileConn <- file(file.path(outstub, "static_sample.txt"))
  writeLines(txt_static_sample, fileConn)
  close(fileConn)
  

  txt_static_ab <- c("<tab:static_ab>")
  for (xvar in c("mw_res", "mw_wkp_tot_17")) {
    txt_static_ab <- c(txt_static_ab, 
                      paste(est[model == "baseline" & var == xvar,]$b,
                            est[model == "AB"       & var == xvar,]$b,
                            sep = "\t"))
    txt_static_ab <- c(txt_static_ab, 
                      paste(est[model == "baseline" & var == xvar,]$se,
                            est[model == "AB"       & var == xvar,]$se,
                            sep = "\t"))
  }

  txt_static_ab <- c(txt_static_ab,
                  paste(est[model == "AB" & var == "L_ln_rents",]$b,
                        sep = "\t"))
  txt_static_ab <- c(txt_static_ab,
                  paste(est[model == "AB" & var == "L_ln_rents",]$se,
                        sep = "\t"))
  
  for (stat in c("p_equality", "r2", "N")) {
    txt_static_ab <- c(txt_static_ab, 
                        paste(est[model == "baseline" & var == "mw_wkp_tot_17",][[stat]],
                              est[model == "AB"       & var == "mw_wkp_tot_17",][[stat]],
                              sep = "\t"))
  }

  fileConn <- file(file.path(outstub, "static_ab.txt"))
  writeLines(txt_static_ab, fileConn)
  close(fileConn) 
}


main()
