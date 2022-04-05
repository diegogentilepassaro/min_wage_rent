remove(list = ls())
library(data.table)

main <- function() {
  instub  <- "../output/"
  outstub <- "../output/"
  
  est <- fread(file.path(instub, "estimates_static.csv"))

  # Robustness Table
  names <- c("baseline", 
             "nocontrols", "countytime_fe", "cbsatime_fe", "statefipstime_fe", "ziptrend",
             paste0("mw_wkp_", c("tot_14", "tot_18", "tot_timevary", "earn_under1250_17", "age_under29_17")))

  txt <- c("<tab:robustness>")
  for (name in names) {
    txt <- c(txt, make_row_robustness(est, name))
  }
  
  fileConn <- file(file.path(outstub, "robustness.txt"))
  writeLines(txt, fileConn)
  close(fileConn)

  # Alternative Zillow categories Table
  names <- c("unbal", 
             "SF", "CC", "Studio", "1BR", "2BR", "3BR", "Mfr5Plus")
  
  txt <- c("<tab:zillow_categories>")
  for (name in names) {
    txt <- c(txt, make_row_robustness(est, name))
  }
  
  fileConn <- file(file.path(outstub, "zillow_categories.txt"))
  writeLines(txt, fileConn)
  close(fileConn)
  
  est[, model := gsub("_rents", "", model)]
  
  # Different samples table
  txt <- c("<tab:static_sample>")
  for (xvar in c("mw_res", "mw_wkp_tot_17")) {
    txt  <- c(txt, 
              paste(est[model == "baseline"           & var == xvar,]$b,
                    est[model == "baseline_wgt"       & var == xvar,]$b,
                    est[model == "fullbal"            & var == xvar,]$b,
                    est[model == "fullbal_wgt"        & var == xvar,]$b,
                    est[model == "unbal_by_entry"     & var == xvar,]$b,
                    est[model == "unbal_by_entry_wgt" & var == xvar,]$b,
                    sep = "\t"))
    txt  <- c(txt, 
              paste(est[model == "baseline"           & var == xvar,]$se,
                    est[model == "baseline_wgt"       & var == xvar,]$se,
                    est[model == "fullbal"            & var == xvar,]$se,
                    est[model == "fullbal_wgt"        & var == xvar,]$se,
                    est[model == "unbal_by_entry"     & var == xvar,]$se,
                    est[model == "unbal_by_entry_wgt" & var == xvar,]$se,
                    sep = "\t"))
  }

  for (stat in c("p_equality", "r2", "N")) {
    txt  <- c(txt, 
              paste(est[model == "baseline"           & var == "cumsum_from0",][[stat]],
                    est[model == "baseline_wgt"       & var == "cumsum_from0",][[stat]],
                    est[model == "fullbal"            & var == "cumsum_from0",][[stat]],
                    est[model == "fullbal_wgt"        & var == "cumsum_from0",][[stat]],
                    est[model == "unbal_by_entry"     & var == "cumsum_from0",][[stat]],
                    est[model == "unbal_by_entry_wgt" & var == "cumsum_from0",][[stat]],
                    sep = "\t"))
  }

  fileConn <- file(file.path(outstub, "static_sample.txt"))
  writeLines(txt, fileConn)
  close(fileConn)
  
  # AB table
  txt_ab <- c("<tab:static_ab>")
  for (xvar in c("mw_res", "mw_wkp_tot_17")) {
    txt_ab <- c(txt_ab, 
                paste(est[model == "baseline" & var == xvar,]$b,
                      est[model == "AB"       & var == xvar,]$b,
                      sep = "\t"))
    txt_ab <- c(txt_ab, 
                paste(est[model == "baseline" & var == xvar,]$se,
                      est[model == "AB"       & var == xvar,]$se,
                      sep = "\t"))
  }

  txt_ab <- c(txt_ab,
              paste(est[model == "AB" & var == "L_ln_rents",]$b,
                    sep = "\t"))
  txt_ab <- c(txt_ab,
              paste(est[model == "AB" & var == "L_ln_rents",]$se,
                    sep = "\t"))
  
  for (stat in c("p_equality", "N")) {
    txt_ab <- c(txt_ab, 
                paste(est[model == "baseline" & var == "mw_wkp_tot_17",][[stat]],
                      est[model == "AB"       & var == "mw_wkp_tot_17",][[stat]],
                      sep = "\t"))
  }

  fileConn <- file(file.path(outstub, "static_ab.txt"))
  writeLines(txt_ab, fileConn)
  close(fileConn) 
}

make_row_robustness <- function(est, name) {
  
  mw_wkp_var <- "mw_wkp_tot_17"
  if (grepl("mw_wkp", name)) {
    mw_wkp_var <- name
  }
  
  name_wkp   <- paste0(name, "_wkp_mw_on_res_mw")
  name_rents <- paste0(name, "_rents")
  
  coeffs  <- paste(est[model == name_wkp   & var == "mw_res"      ]$b,
                   est[model == name_rents & var == "mw_res"      ]$b,
                   est[model == name_rents & var == mw_wkp_var    ]$b,
                   est[model == name_rents & var == "cumsum_from0"]$b,
                   est[model == name_rents & var == "mw_res"      ]$N,  sep = "\t")
  stderrs <- paste(est[model == name_wkp   & var == "mw_res"      ]$se,
                   est[model == name_rents & var == "mw_res"      ]$se,
                   est[model == name_rents & var == mw_wkp_var    ]$se,
                   est[model == name_rents & var == "cumsum_from0"]$se, sep = "\t")
  
  return(c(coeffs, stderrs))
}


main()
