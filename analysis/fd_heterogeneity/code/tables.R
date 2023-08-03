remove(list = ls())
library(data.table)
library(haven)

main <- function() {
  instub  <- "../output/"
  outstub <- "../output/"
  
  est <- fread(file.path(instub, "estimates_het.csv"))
  dt  <- read_dta("../temp/fullbal_sample_with_vars_for_het.dta")
  setDT(dt)
  
  txt <- c("<tab:heterogeneity>")
  txt <- c(txt, 
           paste(est[model == "static_both"    & var == "mw_res",]$b,
                 est[model == "het_mw_shares"  & var == "mw_res_std_sh_mw_wkrs_statutory" & at == 0,]$b,
                 est[model == "het_med_inc"    & var == "mw_res_std_med_hhld_inc" & at == 0,]$b,
                 est[model == "het_public_hous"& var == "mw_res_high_public_hous" & at == 0,]$b,
                 sep = "\t"))

  txt <- c(txt, 
           paste(est[model == "static_both"    & var == "mw_res",]$se,
                 est[model == "het_mw_shares"  & var == "mw_res_std_sh_mw_wkrs_statutory" & at == 0,]$se,
                 est[model == "het_med_inc"    & var == "mw_res_std_med_hhld_inc" & at == 0,]$se,
                 est[model == "het_public_hous"& var == "mw_res_high_public_hous" & at == 0,]$se,
                 sep = "\t"))

  txt <- c(txt, 
           paste(est[model == "het_mw_shares" & var == "mw_res_std_sh_mw_wkrs_statutory" & at == 1,]$b, 
                 sep = "\t"),
            paste(est[model == "het_mw_shares" & var == "mw_res_std_sh_mw_wkrs_statutory" & at == 1,]$se, 
                 sep = "\t"))

  txt <- c(txt, 
           paste(est[model == "het_med_inc" & var == "mw_res_std_med_hhld_inc" & at == 1,]$b, 
                 sep = "\t"),
            paste(est[model == "het_med_inc" & var == "mw_res_std_med_hhld_inc" & at == 1,]$se, 
                 sep = "\t"))

  txt <- c(txt, 
           paste(est[model == "het_public_hous" & var == "mw_res_high_public_hous" & at == 1,]$b, 
                 sep = "\t"),
            paste(est[model == "het_public_hous" & var == "mw_res_high_public_hous" & at == 1,]$se, 
                 sep = "\t"))

  txt <- c(txt, 
           paste(est[model == "static_both"    & var == "mw_wkp_tot_17",]$b,
                 est[model == "het_mw_shares"  & var == "mw_wkp_std_sh_mw_wkrs_statutory" & at == 0,]$b,
                 est[model == "het_med_inc"    & var == "mw_wkp_std_med_hhld_inc" & at == 0,]$b,
                 est[model == "het_public_hous"& var == "mw_wkp_high_public_hous" & at == 0,]$b,
                 sep = "\t"))

  txt <- c(txt, 
           paste(est[model == "static_both"    & var == "mw_wkp_tot_17",]$se,
                 est[model == "het_mw_shares"  & var == "mw_wkp_std_sh_mw_wkrs_statutory" & at == 0,]$se,
                 est[model == "het_med_inc"    & var == "mw_wkp_std_med_hhld_inc" & at == 0,]$se,
                 est[model == "het_public_hous"& var == "mw_wkp_high_public_hous" & at == 0,]$se,
                 sep = "\t"))

  txt <- c(txt, 
           paste(est[model == "het_mw_shares" & var == "mw_wkp_std_sh_mw_wkrs_statutory" & at == 1,]$b, 
                 sep = "\t"),
            paste(est[model == "het_mw_shares" & var == "mw_wkp_std_sh_mw_wkrs_statutory" & at == 1,]$se, 
                 sep = "\t"))

  txt <- c(txt, 
           paste(est[model == "het_med_inc" & var == "mw_wkp_std_med_hhld_inc" & at == 1,]$b, 
                 sep = "\t"),
            paste(est[model == "het_med_inc" & var == "mw_wkp_std_med_hhld_inc" & at == 1,]$se, 
                 sep = "\t"))

   txt <- c(txt, 
           paste(est[model == "het_public_hous" & var == "mw_wkp_high_public_hous" & at == 1,]$b, 
                 sep = "\t"),
            paste(est[model == "het_public_hous" & var == "mw_wkp_high_public_hous" & at == 1,]$se, 
                 sep = "\t"))
   
   txt <- c(txt, 
            paste(unique(dt$avg_sh_mw_wkrs_statutory),
                  unique(dt$avg_med_hhld_inc_acs2014),
                  unique(dt$avg_sh_public_housing),
                  sep = "\t"))
   
   txt <- c(txt, 
            paste(unique(dt$sd_sh_mw_wkrs_statutory),
                  unique(dt$sd_med_hhld_inc_acs2014),
                  unique(dt$sd_sh_public_housing),
                  sep = "\t"))
   
  txt <- c(txt, 
           paste(est[model == "static_both"    & var == "mw_wkp_tot_17",]$r2,
                 est[model == "het_mw_shares"  & var == "mw_wkp_std_sh_mw_wkrs_statutory" & at == 0,]$r2,
                 est[model == "het_med_inc"    & var == "mw_wkp_std_med_hhld_inc" & at == 0,]$r2,
                 est[model == "het_public_hous"& var == "mw_wkp_high_public_hous" & at == 0,]$r2,
                 sep = "\t"))

  txt <- c(txt, 
           paste(est[model == "static_both"    & var == "mw_wkp_tot_17",]$N,
                 est[model == "het_mw_shares"  & var == "mw_wkp_std_sh_mw_wkrs_statutory" & at == 0,]$N,
                 est[model == "het_med_inc"    & var == "mw_wkp_std_med_hhld_inc" & at == 0,]$N,
                 est[model == "het_public_hous"& var == "mw_wkp_high_public_hous" & at == 0,]$N,
                 sep = "\t"))

  fileConn <- file(file.path(outstub, "heterogeneity.txt"))
  writeLines(txt, fileConn)
  close(fileConn)
}

main()
