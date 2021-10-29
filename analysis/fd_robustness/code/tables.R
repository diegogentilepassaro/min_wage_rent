remove(list = ls())
library(data.table)

main <- function() {
  instub  <- "../output/"
  outstub <- "../output/"
  
  est <- fread(file.path(instub, "estimates_static.csv"))


  txt_static_sample <- c("<tab:static_sample>")
  for (xvar in c("ln_mw", "exp_ln_mw_17")) {
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
  for (xvar in c("ln_mw", "exp_ln_mw_17")) {
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
                        paste(est[model == "baseline" & var == "exp_ln_mw_17",][[stat]],
                              est[model == "AB"       & var == "exp_ln_mw_17",][[stat]],
                              sep = "\t"))
  }

  fileConn <- file(file.path(outstub, "static_ab.txt"))
  writeLines(txt_static_ab, fileConn)
  close(fileConn) 


  txt_static_robust <- c("<tab:static_robust>")
  for (xvar in c("ln_mw", "exp_ln_mw_17")) {
    txt_static_robust <- c(txt_static_robust,
                           paste(est[model == "baseline"        & var == xvar,]$b,
                                 est[model == "nocontrols"      & var == xvar,]$b,
                                 est[model == "zip_spec_trend"  & var == xvar,]$b,
                                 est[model == "county_timefe"   & var == xvar,]$b,
                                 est[model == "cbsa_timefe"     & var == xvar,]$b,
                                 est[model == "state_timefe"    & var == xvar,]$b,
                                 sep = "\t"))
    txt_static_robust <- c(txt_static_robust,
                           paste(est[model == "baseline"        & var == xvar,]$se,
                                 est[model == "nocontrols"      & var == xvar,]$se,
                                 est[model == "zip_spec_trend"  & var == xvar,]$se,
                                 est[model == "county_timefe"   & var == xvar,]$se,
                                 est[model == "cbsa_timefe"     & var == xvar,]$se,
                                 est[model == "state_timefe"    & var == xvar,]$se,
                                 sep = "\t"))
  }
  for (stat in c("p_equality", "r2", "N")) {
    txt_static_robust <- c(txt_static_robust, 
                          paste(est[model == "baseline"       & var == "exp_ln_mw_17",][[stat]],
                                est[model == "nocontrols"     & var == "exp_ln_mw_17",][[stat]],
                                est[model == "zip_spec_trend" & var == "exp_ln_mw_17",][[stat]],
                                est[model == "county_timefe"  & var == "exp_ln_mw_17",][[stat]],
                                est[model == "cbsa_timefe"    & var == "exp_ln_mw_17",][[stat]],
                                est[model == "state_timefe"   & var == "exp_ln_mw_17",][[stat]],
                                sep = "\t"))
  }
  fileConn <- file(file.path(outstub, "static_robust.txt"))
  writeLines(txt_static_robust, fileConn)
  close(fileConn)
  
  
  
  txt_static_robust <- c("<tab:static_expMW_sensitivity>")
  txt_static_robust <- c(txt_static_robust,
                         paste(est[model == "baseline_exp_ln_mw_10"                 & var == "ln_mw",]$b,
                               est[model == "baseline_exp_ln_mw_14"                 & var == "ln_mw",]$b,
                               est[model == "baseline_exp_ln_mw_18"                 & var == "ln_mw",]$b,
                               est[model == "baseline_exp_ln_mw_earn_under1250_14"  & var == "ln_mw",]$b,
                               est[model == "baseline_exp_ln_mw_age_under29_14"     & var == "ln_mw",]$b,
                               sep = "\t"))
  txt_static_robust <- c(txt_static_robust,
                         paste(est[model == "baseline_exp_ln_mw_10"                 & var == "ln_mw",]$se,
                               est[model == "baseline_exp_ln_mw_14"                 & var == "ln_mw",]$se,
                               est[model == "baseline_exp_ln_mw_18"                 & var == "ln_mw",]$se,
                               est[model == "baseline_exp_ln_mw_earn_under1250_14"  & var == "ln_mw",]$se,
                               est[model == "baseline_exp_ln_mw_age_under29_14"     & var == "ln_mw",]$se,
                               sep = "\t"))
  
  txt_static_robust <- c(txt_static_robust,
                         paste(est[model == "baseline_exp_ln_mw_10"                 & var == "exp_ln_mw_10",]$b,
                               est[model == "baseline_exp_ln_mw_14"                 & var == "exp_ln_mw_14",]$b,
                               est[model == "baseline_exp_ln_mw_18"                 & var == "exp_ln_mw_18",]$b,
                               est[model == "baseline_exp_ln_mw_earn_under1250_14"  & var == "exp_ln_mw_earn_under1250_14",]$b,
                               est[model == "baseline_exp_ln_mw_age_under29_14"     & var == "exp_ln_mw_age_under29_14",]$b,
                               sep = "\t"))
  txt_static_robust <- c(txt_static_robust,
                         paste(est[model == "baseline_exp_ln_mw_10"                 & var == "exp_ln_mw_10",]$se,
                               est[model == "baseline_exp_ln_mw_14"                 & var == "exp_ln_mw_14",]$se,
                               est[model == "baseline_exp_ln_mw_18"                 & var == "exp_ln_mw_18",]$se,
                               est[model == "baseline_exp_ln_mw_earn_under1250_14"  & var == "exp_ln_mw_earn_under1250_14",]$se,
                               est[model == "baseline_exp_ln_mw_age_under29_14"     & var == "exp_ln_mw_age_under29_14",]$se,
                               sep = "\t"))
  
  for (stat in c("p_equality", "r2", "N")) {
    txt_static_robust <- c(txt_static_robust, 
                           paste(est[model == "baseline_exp_ln_mw_10"                 & var == "ln_mw",][[stat]],
                                 est[model == "baseline_exp_ln_mw_14"                 & var == "ln_mw",][[stat]],
                                 est[model == "baseline_exp_ln_mw_18"                 & var == "ln_mw",][[stat]],
                                 est[model == "baseline_exp_ln_mw_earn_under1250_14"  & var == "ln_mw",][[stat]],
                                 est[model == "baseline_exp_ln_mw_age_under29_14"     & var == "ln_mw",][[stat]],
                                 sep = "\t"))
  }
  fileConn <- file(file.path(outstub, "static_expMW_sensitivity.txt"))
  writeLines(txt_static_robust, fileConn)
  close(fileConn)
}


main()
