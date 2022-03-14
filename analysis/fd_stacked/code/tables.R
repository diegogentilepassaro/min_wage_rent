remove(list = ls())
library(data.table)

main <- function() {
  instub  <- "../output/"
  outstub <- "../output/"
  
  est <- fread(file.path(instub, "estimates_stacked_static_w6.csv"))
  
  txt <- c("<tab:stacked_w6>")
  txt <- c(txt,
           paste(est[model == "mw_wkp_on_res_mw_w6" & var == "d_mw_res"]$b,
                 est[model == "static_mw_res_w6"     & var == "d_mw_res"]$b,
                 est[model == "static_both_w6"       & var == "d_mw_res"]$b,  sep = "\t"),
            paste(est[model == "mw_wkp_on_res_mw_w6" & var == "d_mw_res"]$se,
                 est[model == "static_mw_res_w6"     & var == "d_mw_res"]$se, 
                 est[model == "static_both_w6"       & var == "d_mw_res"]$se, sep = "\t"))
  
  txt <- c(txt,
           paste(est[model == "static_mw_wkp_w6" & var == "d_mw_wkp_tot_17"]$b, 
                 est[model == "static_both_w6"   & var == "d_mw_wkp_tot_17"]$b, sep = "\t"),
           paste(est[model == "static_mw_wkp_w6" & var == "d_mw_wkp_tot_17"]$se, 
                 est[model == "static_both_w6"   & var == "d_mw_wkp_tot_17"]$se, sep = "\t"))
  
  txt <- c(txt, paste0(est[model == "static_both_w6" & var == "cumsum_from0"]$b))
  txt <- c(txt, paste0(est[model == "static_both_w6" & var == "cumsum_from0"]$se))
  txt <- c(txt, paste0(est[model == "static_both_w6" & var == "cumsum_from0"]$p_equality))
  
  txt <- c(txt,
           paste(est[model == "mw_wkp_on_res_mw_w6" & var == "d_mw_res"]$r2,
                 est[model == "static_mw_res_w6"    & var == "d_mw_res"]$r2, 
                 est[model == "static_mw_wkp_w6"    & var == "d_mw_wkp_tot_17"]$r2, 
                 est[model == "static_both_w6"      & var == "d_mw_res"]$r2, sep = "\t"),
           paste(est[model == "mw_wkp_on_res_mw_w6" & var == "d_mw_res"]$N,
                 est[model == "static_mw_res_w6"    & var == "d_mw_res"]$N, 
                 est[model == "static_mw_wkp_w6"    & var == "d_mw_wkp_tot_17"]$N, 
                 est[model == "static_both_w6"      & var == "d_mw_res"]$N, sep = "\t"))
  
  fileConn <- file(file.path(outstub, "stacked_w6.txt"))
  writeLines(txt, fileConn)
  close(fileConn)
}

main()
