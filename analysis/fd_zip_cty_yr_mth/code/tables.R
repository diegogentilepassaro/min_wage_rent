remove(list = ls())
library(data.table)

main <- function() {
  instub  <- "../output/"
  outstub <- "../output/"
  
  est <- fread(file.path(instub, "estimates_static.csv"))

  txt <- c("<tab:cty_vs_zip_mth_vs_yr>")
  txt <- c(txt, make_row_res_only(est, "zipcode"))
  txt <- c(txt, make_row_wkp_only(est, "zipcode"))
  txt <- c(txt, make_row_both(est, "zipcode"))
  txt <- c(txt, make_row_res_only(est, "county"))
  txt <- c(txt, make_row_wkp_only(est, "county"))
  txt <- c(txt, make_row_both(est, "county"))
  txt <- c(txt, make_row_res_only(est, "zipcode", "yr_"))
  txt <- c(txt, make_row_wkp_only(est, "zipcode", "yr_"))
  txt <- c(txt, make_row_both(est, "zipcode", "yr_"))
  txt <- c(txt, make_row_res_only(est, "county", "yr_"))
  txt <- c(txt, make_row_wkp_only(est, "county", "yr_"))
  txt <- c(txt, make_row_both(est, "county", "yr_"))
 
  fileConn <- file(file.path(outstub, "cty_vs_zip_mth_vs_yr.txt"))
  writeLines(txt, fileConn)
  close(fileConn)
}

make_row_res_only <- function(est, geo, stub = "") {
  
  coeffs  <- paste(est[model == paste0(geo, "_", stub, "static_mw_res")      
                       & var == "mw_res"        ]$b,
                   est[model == paste0(geo, "_", stub, "static_mw_res")      
                       & var == "mw_res"        ]$N,  sep = "\t")
  stderrs <- paste(est[model == paste0(geo, "_", stub, "static_mw_res")      
                       & var == "mw_res"        ]$se, sep = "\t")
  
  return(c(coeffs, stderrs))
}

make_row_wkp_only <- function(est, geo, stub = "") {

  coeffs  <- paste(est[model == paste0(geo, "_", stub, "static_mw_wkp")      
                       & var == "mw_wkp_tot_17"        ]$b,
                   est[model == paste0(geo, "_", stub, "static_mw_wkp")      
                       & var == "mw_wkp_tot_17"        ]$N,  sep = "\t")
  stderrs <- paste(est[model == paste0(geo, "_", stub, "static_mw_wkp")      
                       & var == "mw_wkp_tot_17"        ]$se, sep = "\t")
  
  return(c(coeffs, stderrs))
}

make_row_both <- function(est, geo, stub = "") {
  
  coeffs  <- paste(est[model == paste0(geo, "_", stub, "mw_wkp_on_res_mw")   
                       & var == "mw_res"        ]$b,
                   est[model == paste0(geo, "_", stub, "static_both")        
                       & var == "mw_res"        ]$b,
                   est[model == paste0(geo, "_", stub, "static_both")        
                       & var == "mw_wkp_tot_17" ]$b,
                   est[model == paste0(geo, "_", stub, "static_both")        
                       & var == "cumsum_from0"  ]$b,
                   est[model == paste0(geo, "_", stub, "static_both")        
                       & var == "mw_res"        ]$N,  sep = "\t")
  stderrs <- paste(est[model == paste0(geo, "_", stub, "mw_wkp_on_res_mw")   
                       & var == "mw_res"        ]$se,
                   est[model == paste0(geo, "_", stub, "static_both")        
                       & var == "mw_res"        ]$se,
                   est[model == paste0(geo, "_", stub, "static_both")        
                       & var == "mw_wkp_tot_17" ]$se,
                   est[model == paste0(geo, "_", stub, "static_both")        
                       & var == "cumsum_from0"  ]$se, sep = "\t")
  
  return(c(coeffs, stderrs))
}

main()
