remove(list = ls())
library(data.table)

main <- function() {
  instub  <- "../output/"
  outstub <- "../output/"
  
  est <- fread(file.path(instub, "estimates_static.csv"))


  txt_static_sample <- c("<tab:static_sample>")
  for (xvar in c("ln_mw", "exp_ln_mw_17", "cumsum_from0")) {
    txt_static_sample <- c(txt_static_sample, 
                            paste(est[model == "static_baseline"     & var == xvar,]$b,
                                  est[model == "static_baseline_wgt" & var == xvar,]$b,
                                  est[model == "static_unbal"        & var == xvar,]$b,
                                  est[model == "static_unbal_wgt"    & var == xvar,]$b,
                                  est[model == "static_fullbal"      & var == xvar,]$b,
                                  est[model == "static_fullbal_wgt"  & var == xvar,]$b,
                                  sep = "\t"))
    txt_static_sample <- c(txt_static_sample, 
                            paste(est[model == "static_baseline"     & var == xvar,]$se,
                                  est[model == "static_baseline_wgt" & var == xvar,]$se,
                                  est[model == "static_unbal"        & var == xvar,]$se,
                                  est[model == "static_unbal_wgt"    & var == xvar,]$se,
                                  est[model == "static_fullbal"      & var == xvar,]$se,
                                  est[model == "static_fullbal_wgt"  & var == xvar,]$se,
                                  sep = "\t"))
  }

  for (stat in c("p_equality", "r2", "N")) {
    txt_static_sample <- c(txt_static_sample, 
                            paste(est[model == "static_baseline"     & var == "cumsum_from0",][[stat]],
                                  est[model == "static_baseline_wgt" & var == "cumsum_from0",][[stat]],
                                  est[model == "static_unbal"        & var == "cumsum_from0",][[stat]],
                                  est[model == "static_unbal_wgt"    & var == "cumsum_from0",][[stat]],
                                  est[model == "static_fullbal"      & var == "cumsum_from0",][[stat]],
                                  est[model == "static_fullbal_wgt"  & var == "cumsum_from0",][[stat]],
                                  sep = "\t"))
  }

  fileConn <- file(file.path(outstub, "static_sample.txt"))
  writeLines(txt_static_sample, fileConn)
  close(fileConn)
  

  txt_static_ab <- c("<tab:static_ab>")
  for (xvar in c("ln_mw", "exp_ln_mw_17")) {
    txt_static_ab <- c(txt_static_ab, 
                      paste(est[model == "static_baseline" & var == xvar,]$b,
                            est[model == "static_AB"       & var == xvar,]$b,
                            sep = "\t"))
    txt_static_ab <- c(txt_static_ab, 
                      paste(est[model == "static_baseline" & var == xvar,]$se,
                            est[model == "static_AB"       & var == xvar,]$se,
                            sep = "\t"))
  }

  txt_static_ab <- c(txt_static_ab,
                  paste(est[model == "static_AB" & var == "L_ln_rents",]$b,
                        sep = "\t"))
  txt_static_ab <- c(txt_static_ab,
                  paste(est[model == "static_AB" & var == "L_ln_rents",]$se,
                        sep = "\t"))
  
  for (stat in c("p_equality", "r2", "N")) {
    txt_static_ab <- c(txt_static_ab, 
                        paste(est[model == "static_baseline" & var == "exp_ln_mw_17",][[stat]],
                              est[model == "static_AB"       & var == "exp_ln_mw_17",][[stat]],
                              sep = "\t"))
  }

  fileConn <- file(file.path(outstub, "static_ab.txt"))
  writeLines(txt_static_ab, fileConn)
  close(fileConn) 


  txt_static_robust <- c("<tab:static_robust>")
  for (xvar in c("ln_mw", "exp_ln_mw_17", "cumsum_from0")) {
    txt_static_robust <- c(txt_static_robust,
                           paste(est[model == "static_baseline"            & var == xvar,]$b,
                                 est[model == "static_nocontrols"          & var == xvar,]$b,
                                 est[model == "static_zip_spec_trend"      & var == xvar,]$b,
                                 est[model == "static_state_county_timefe" & var == xvar,]$b,
                                 est[model == "static_state_cbsa_timefe"   & var == xvar,]$b,
                                 sep = "\t"))
    txt_static_robust <- c(txt_static_robust,
                           paste(est[model == "static_baseline"            & var == xvar,]$se,
                                 est[model == "static_nocontrols"          & var == xvar,]$se,
                                 est[model == "static_zip_spec_trend"      & var == xvar,]$se,
                                 est[model == "static_state_county_timefe" & var == xvar,]$se,
                                 est[model == "static_state_cbsa_timefe"   & var == xvar,]$se,
                                 sep = "\t"))
  }
  for (stat in c("p_equality", "r2", "N")) {
    txt_static_robust <- c(txt_static_robust, 
                          paste(est[model == "static_baseline"            & var == "exp_ln_mw_17",][[stat]],
                                est[model == "static_nocontrols"          & var == "exp_ln_mw_17",][[stat]],
                                est[model == "static_zip_spec_trend"      & var == "exp_ln_mw_17",][[stat]],
                                est[model == "static_state_county_timefe" & var == "exp_ln_mw_17",][[stat]],
                                est[model == "static_state_cbsa_timefe"   & var == "exp_ln_mw_17",][[stat]],
                                sep = "\t"))
  }
  fileConn <- file(file.path(outstub, "static_robust.txt"))
  writeLines(txt_static_robust, fileConn)
  close(fileConn)
}


main()
