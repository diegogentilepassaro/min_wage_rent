remove(list = ls())
library(data.table)

main <- function() {
  instub  <- "../output/"
  outstub <- "../output/"
  
  est <- read.csv(file.path(instub, "estimates_static.csv"))

  txt_static_sample <- c("<tab:static_sample>")
  txt_static_sample <- c(txt_static_sample, 
                         paste(est[est$model == "static_baseline"& est$var == "ln_mw",]$b,
                               est[est$model == "static_baseline_unbal"& est$var == "ln_mw",]$b,
                               est[est$model == "static_baseline_wgt"& est$var == "ln_mw",]$b,
                               est[est$model == "static_baseline_unbal_wgt"& est$var == "ln_mw",]$b,
                               est[est$model == "static_baseline_fullbal"& est$var == "ln_mw",]$b,
                               est[est$model == "static_baseline_fullbal_wgt"& est$var == "ln_mw",]$b,
                               sep = "\t"))
  txt_static_sample <- c(txt_static_sample, 
                         paste(est[est$model == "static_baseline"& est$var == "ln_mw",]$se,
                               est[est$model == "static_baseline_unbal"& est$var == "ln_mw",]$se,
                               est[est$model == "static_baseline_wgt"& est$var == "ln_mw",]$se,
                               est[est$model == "static_baseline_unbal_wgt"& est$var == "ln_mw",]$se,
                               est[est$model == "static_baseline_fullbal"& est$var == "ln_mw",]$se,
                               est[est$model == "static_baseline_fullbal_wgt"& est$var == "ln_mw",]$se,
                               sep = "\t"))
  txt_static_sample <- c(txt_static_sample, 
                         paste(est[est$model == "static_baseline"& est$var == "exp_ln_mw_17",]$b,
                               est[est$model == "static_baseline_unbal"& est$var == "exp_ln_mw_17",]$b,
                               est[est$model == "static_baseline_wgt"& est$var == "exp_ln_mw_17",]$b,
                               est[est$model == "static_baseline_unbal_wgt"& est$var == "exp_ln_mw_17",]$b,
                               est[est$model == "static_baseline_fullbal"& est$var == "exp_ln_mw_17",]$b,
                               est[est$model == "static_baseline_fullbal_wgt"& est$var == "exp_ln_mw_17",]$b,
                               sep = "\t"))
  txt_static_sample <- c(txt_static_sample, 
                         paste(est[est$model == "static_baseline"& est$var == "exp_ln_mw_17",]$se,
                               est[est$model == "static_baseline_unbal"& est$var == "exp_ln_mw_17",]$se,
                               est[est$model == "static_baseline_wgt"& est$var == "exp_ln_mw_17",]$se,
                               est[est$model == "static_baseline_unbal_wgt"& est$var == "exp_ln_mw_17",]$se,
                               est[est$model == "static_baseline_fullbal"& est$var == "exp_ln_mw_17",]$se,
                               est[est$model == "static_baseline_fullbal_wgt"& est$var == "exp_ln_mw_17",]$se,
                               sep = "\t"))  
  txt_static_sample <- c(txt_static_sample, 
                         paste(est[est$model == "static_baseline"& est$var == "cumsum_from0",]$b,
                               est[est$model == "static_baseline_unbal"& est$var == "cumsum_from0",]$b,
                               est[est$model == "static_baseline_wgt"& est$var == "cumsum_from0",]$b,
                               est[est$model == "static_baseline_unbal_wgt"& est$var == "cumsum_from0",]$b,
                               est[est$model == "static_baseline_fullbal"& est$var == "cumsum_from0",]$b,
                               est[est$model == "static_baseline_fullbal_wgt"& est$var == "cumsum_from0",]$b,
                               sep = "\t"))
  txt_static_sample <- c(txt_static_sample, 
                         paste(est[est$model == "static_baseline"& est$var == "cumsum_from0",]$se,
                               est[est$model == "static_baseline_unbal"& est$var == "cumsum_from0",]$se,
                               est[est$model == "static_baseline_wgt"& est$var == "cumsum_from0",]$se,
                               est[est$model == "static_baseline_unbal_wgt"& est$var == "cumsum_from0",]$se,
                               est[est$model == "static_baseline_fullbal"& est$var == "cumsum_from0",]$se,
                               est[est$model == "static_baseline_fullbal_wgt"& est$var == "cumsum_from0",]$se,
                               sep = "\t"))   
  txt_static_sample <- c(txt_static_sample, 
                         paste(est[est$model == "static_baseline"& est$var == "cumsum_from0",]$p_equality,
                               est[est$model == "static_baseline_unbal"& est$var == "cumsum_from0",]$p_equality,
                               est[est$model == "static_baseline_wgt"& est$var == "cumsum_from0",]$p_equality,
                               est[est$model == "static_baseline_unbal_wgt"& est$var == "cumsum_from0",]$p_equality,
                               est[est$model == "static_baseline_fullbal"& est$var == "cumsum_from0",]$p_equality,
                               est[est$model == "static_baseline_fullbal_wgt"& est$var == "cumsum_from0",]$p_equality,
                               sep = "\t"))
  txt_static_sample <- c(txt_static_sample, 
                         paste(est[est$model == "static_baseline"& est$var == "cumsum_from0",]$r2,
                               est[est$model == "static_baseline_unbal"& est$var == "cumsum_from0",]$r2,
                               est[est$model == "static_baseline_wgt"& est$var == "cumsum_from0",]$r2,
                               est[est$model == "static_baseline_unbal_wgt"& est$var == "cumsum_from0",]$r2,
                               est[est$model == "static_baseline_fullbal"& est$var == "cumsum_from0",]$r2,
                               est[est$model == "static_baseline_fullbal_wgt"& est$var == "cumsum_from0",]$r2,
                               sep = "\t")) 
  txt_static_sample <- c(txt_static_sample, 
                         paste(est[est$model == "static_baseline"& est$var == "cumsum_from0",]$N,
                               est[est$model == "static_baseline_unbal"& est$var == "cumsum_from0",]$N,
                               est[est$model == "static_baseline_wgt"& est$var == "cumsum_from0",]$N,
                               est[est$model == "static_baseline_unbal_wgt"& est$var == "cumsum_from0",]$N,
                               est[est$model == "static_baseline_fullbal"& est$var == "cumsum_from0",]$N,
                               est[est$model == "static_baseline_fullbal_wgt"& est$var == "cumsum_from0",]$N,
                               sep = "\t"))   
  fileConn <- file(file.path(outstub, "static_sample.txt"))
  writeLines(txt_static_sample, fileConn)
  close(fileConn)
  
  txt_static_ab <- c("<tab:static_ab>")
  txt_static_ab <- c(txt_static_ab, 
                     paste(est[est$model == "static_baseline"& est$var == "ln_mw",]$b,
                           est[est$model == "static_baseline_AB"& est$var == "ln_mw",]$b,
                           sep = "\t"))
  txt_static_ab <- c(txt_static_ab, 
                     paste(est[est$model == "static_baseline"& est$var == "ln_mw",]$se,
                           est[est$model == "static_baseline_AB"& est$var == "ln_mw",]$se,
                           sep = "\t"))
  txt_static_ab <- c(txt_static_ab, 
                     paste(est[est$model == "static_baseline"& est$var == "exp_ln_mw_17",]$b,
                           est[est$model == "static_baseline_AB"& est$var == "exp_ln_mw_17",]$b,
                           sep = "\t"))
  txt_static_ab <- c(txt_static_ab, 
                     paste(est[est$model == "static_baseline"& est$var == "exp_ln_mw_17",]$se,
                           est[est$model == "static_baseline_AB"& est$var == "exp_ln_mw_17",]$se,
                           sep = "\t"))
  txt_static_ab <- c(txt_static_ab, 
                     paste("",
                           est[est$model == "static_baseline_AB"& est$var == "L_ln_rents",]$b,
                           sep = "\t"))
  txt_static_ab <- c(txt_static_ab, 
                     paste("",
                           est[est$model == "static_baseline_AB"& est$var == "L_ln_rents",]$se,
                           sep = "\t"))
  txt_static_ab <- c(txt_static_ab, 
                     paste(est[est$model == "static_baseline"& est$var == "exp_ln_mw_17",]$p_equality,
                           est[est$model == "static_baseline_AB"& est$var == "exp_ln_mw_17",]$p_equality,
                           sep = "\t"))
  txt_static_ab <- c(txt_static_ab, 
                     paste(est[est$model == "static_baseline"& est$var == "exp_ln_mw_17",]$r2,
                           est[est$model == "static_baseline_AB"& est$var == "exp_ln_mw_17",]$r2,
                           sep = "\t"))
  txt_static_ab <- c(txt_static_ab, 
                     paste(est[est$model == "static_baseline"& est$var == "exp_ln_mw_17",]$N,
                           est[est$model == "static_baseline_AB"& est$var == "exp_ln_mw_17",]$N,
                           sep = "\t"))
  fileConn <- file(file.path(outstub, "static_ab.txt"))
  writeLines(txt_static_ab, fileConn)
  close(fileConn) 
  
  txt_static_robust <- c("<tab:static_robust>")
  txt_static_robust <- c(txt_static_robust, 
                         paste(est[est$model == "static_baseline"& est$var == "ln_mw",]$b,
                               est[est$model == "static_baseline_nocontrols"& est$var == "ln_mw",]$b,
                               est[est$model == "static_baseline_zip_spec_trend"& est$var == "ln_mw",]$b,
                               est[est$model == "static_baseline_state_county_timefe"& est$var == "ln_mw",]$b,
                               est[est$model == "static_baseline_state_cbsa_timefe"& est$var == "ln_mw",]$b,
                         sep = "\t"))
  txt_static_robust <- c(txt_static_robust, 
                         paste(est[est$model == "static_baseline"& est$var == "ln_mw",]$se,
                               est[est$model == "static_baseline_nocontrols"& est$var == "ln_mw",]$se,
                               est[est$model == "static_baseline_zip_spec_trend"& est$var == "ln_mw",]$se,
                               est[est$model == "static_baseline_state_county_timefe"& est$var == "ln_mw",]$se,
                               est[est$model == "static_baseline_state_cbsa_timefe"& est$var == "ln_mw",]$se,
                               sep = "\t"))
  txt_static_robust <- c(txt_static_robust, 
                         paste(est[est$model == "static_baseline"& est$var == "exp_ln_mw_17",]$b,
                               est[est$model == "static_baseline_nocontrols"& est$var == "exp_ln_mw_17",]$b,
                               est[est$model == "static_baseline_zip_spec_trend"& est$var == "exp_ln_mw_17",]$b,
                               est[est$model == "static_baseline_state_county_timefe"& est$var == "exp_ln_mw_17",]$b,
                               est[est$model == "static_baseline_state_cbsa_timefe"& est$var == "exp_ln_mw_17",]$b,
                               sep = "\t"))
  txt_static_robust <- c(txt_static_robust, 
                         paste(est[est$model == "static_baseline"& est$var == "exp_ln_mw_17",]$se,
                               est[est$model == "static_baseline_nocontrols"& est$var == "exp_ln_mw_17",]$se,
                               est[est$model == "static_baseline_zip_spec_trend"& est$var == "exp_ln_mw_17",]$se,
                               est[est$model == "static_baseline_state_county_timefe"& est$var == "exp_ln_mw_17",]$se,
                               est[est$model == "static_baseline_state_cbsa_timefe"& est$var == "exp_ln_mw_17",]$se,
                               sep = "\t"))
  txt_static_robust <- c(txt_static_robust, 
                         paste(est[est$model == "static_baseline"& est$var == "cumsum_from0",]$b,
                               est[est$model == "static_baseline_nocontrols"& est$var == "cumsum_from0",]$b,
                               est[est$model == "static_baseline_zip_spec_trend"& est$var == "cumsum_from0",]$b,
                               est[est$model == "static_baseline_state_county_timefe"& est$var == "cumsum_from0",]$b,
                               est[est$model == "static_baseline_state_cbsa_timefe"& est$var == "cumsum_from0",]$b,
                               sep = "\t"))
  txt_static_robust <- c(txt_static_robust, 
                         paste(est[est$model == "static_baseline"& est$var == "cumsum_from0",]$se,
                               est[est$model == "static_baseline_nocontrols"& est$var == "cumsum_from0",]$se,
                               est[est$model == "static_baseline_zip_spec_trend"& est$var == "cumsum_from0",]$se,
                               est[est$model == "static_baseline_state_county_timefe"& est$var == "cumsum_from0",]$se,
                               est[est$model == "static_baseline_state_cbsa_timefe"& est$var == "cumsum_from0",]$se,
                               sep = "\t"))
  txt_static_robust <- c(txt_static_robust, 
                         paste(est[est$model == "static_baseline"& est$var == "exp_ln_mw_17",]$p_equality,
                               est[est$model == "static_baseline_nocontrols"& est$var == "exp_ln_mw_17",]$p_equality,
                               est[est$model == "static_baseline_zip_spec_trend"& est$var == "exp_ln_mw_17",]$p_equality,
                               est[est$model == "static_baseline_state_county_timefe"& est$var == "exp_ln_mw_17",]$p_equality,
                               est[est$model == "static_baseline_state_cbsa_timefe"& est$var == "exp_ln_mw_17",]$p_equality,
                               sep = "\t"))
  txt_static_robust <- c(txt_static_robust, 
                         paste(est[est$model == "static_baseline"& est$var == "exp_ln_mw_17",]$r2,
                               est[est$model == "static_baseline_nocontrols"& est$var == "exp_ln_mw_17",]$r2,
                               est[est$model == "static_baseline_zip_spec_trend"& est$var == "exp_ln_mw_17",]$r2,
                               est[est$model == "static_baseline_state_county_timefe"& est$var == "exp_ln_mw_17",]$r2,
                               est[est$model == "static_baseline_state_cbsa_timefe"& est$var == "exp_ln_mw_17",]$r2,
                               sep = "\t"))  
  txt_static_robust <- c(txt_static_robust, 
                         paste(est[est$model == "static_baseline"& est$var == "exp_ln_mw_17",]$N,
                               est[est$model == "static_baseline_nocontrols"& est$var == "exp_ln_mw_17",]$N,
                               est[est$model == "static_baseline_zip_spec_trend"& est$var == "exp_ln_mw_17",]$N,
                               est[est$model == "static_baseline_state_county_timefe"& est$var == "exp_ln_mw_17",]$N,
                               est[est$model == "static_baseline_state_cbsa_timefe"& est$var == "exp_ln_mw_17",]$N,
                               sep = "\t"))  
  fileConn <- file(file.path(outstub, "static_robust.txt"))
  writeLines(txt_static_robust, fileConn)
  close(fileConn)
}




main()
