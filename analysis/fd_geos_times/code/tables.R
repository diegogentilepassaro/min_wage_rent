remove(list = ls())
library(data.table)

main <- function() {
  instub  <- "../output/"
  outstub <- "../output/"
  
  est <- fread(file.path(instub, "estimates_static.csv"))

  txt <- c("<tab:static_geo_times>")
  txt <- c(txt, make_row_res_only(est, "zipcode"))
  txt <- c(txt, make_row_wkp_only(est, "zipcode"))
  txt <- c(txt, make_row_both(est, "zipcode"))
  txt <- c(txt, make_row_res_only(est, "county"))
  txt <- c(txt, make_row_wkp_only(est, "county"))
  txt <- c(txt, make_row_both(est, "county"))
  txt <- c(txt, make_row_res_only(est, "zipcode", "yr_"))
  txt <- c(txt, make_row_wkp_only(est, "zipcode", "yr_"))
  txt <- c(txt, make_row_both(est, "zipcode", "yr_"))
 
  fileConn <- file(file.path(outstub, "static_geo_times.txt"))
  writeLines(txt, fileConn)
  close(fileConn)
}

make_row_res_only <- function(est, geo, stub = "") {
  
  mw_var <- "mw_res"
  if (grepl("yr_", stub)) mw_var <- "d_mw_res_avg"

  coeffs  <- paste(est[model == paste0(geo, "_", stub, "static_mw_res")      
                       & var == mw_var]$b,
                   est[model == paste0(geo, "_", stub, "static_mw_res")      
                       & var == mw_var]$N,  sep = "\t")
  stderrs <- paste(est[model == paste0(geo, "_", stub, "static_mw_res")      
                       & var == mw_var]$se, sep = "\t")
  
  return(c(coeffs, stderrs))
}

make_row_wkp_only <- function(est, geo, stub = "") {

  mw_var <- "mw_wkp_tot_17"
  if (grepl("yr_", stub)) mw_var <- "d_mw_wkp_tot_17_avg"

  coeffs  <- paste(est[model == paste0(geo, "_", stub, "static_mw_wkp")      
                       & var == mw_var]$b,
                   est[model == paste0(geo, "_", stub, "static_mw_wkp")      
                       & var == mw_var]$N,  sep = "\t")
  stderrs <- paste(est[model == paste0(geo, "_", stub, "static_mw_wkp")      
                       & var == mw_var]$se, sep = "\t")
  
  return(c(coeffs, stderrs))
}

make_row_both <- function(est, geo, stub = "") {
  
  mw_res <- "mw_res"
  mw_wkp <- "mw_wkp_tot_17"
  if (grepl("yr_", stub)) {
    mw_res <- "d_mw_res_avg"
    mw_wkp <- "d_mw_wkp_tot_17_avg"
  }

  coeffs  <- paste(est[model == paste0(geo, "_", stub, "mw_wkp_on_res_mw")   
                       & var == mw_res]$b,
                   est[model == paste0(geo, "_", stub, "static_both")        
                       & var == mw_res]$b,
                   est[model == paste0(geo, "_", stub, "static_both")        
                       & var == mw_wkp]$b,
                   est[model == paste0(geo, "_", stub, "static_both")        
                       & var == "cumsum_from0"  ]$b,
                   est[model == paste0(geo, "_", stub, "static_both")        
                       & var == mw_res]$N,  sep = "\t")
  stderrs <- paste(est[model == paste0(geo, "_", stub, "mw_wkp_on_res_mw")   
                       & var == mw_res]$se,
                   est[model == paste0(geo, "_", stub, "static_both")        
                       & var == mw_res]$se,
                   est[model == paste0(geo, "_", stub, "static_both")        
                       & var == mw_wkp]$se,
                   est[model == paste0(geo, "_", stub, "static_both")        
                       & var == "cumsum_from0"  ]$se, sep = "\t")
  
  return(c(coeffs, stderrs))
}

main()
