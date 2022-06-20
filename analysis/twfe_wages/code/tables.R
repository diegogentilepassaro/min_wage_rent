remove(list = ls())
library(data.table)

main <- function() {
  
  instub  <- "../output/"
  outstub <- "../output/"
  
  est <- fread(file.path(instub, "estimates_all.csv"))
  
  tab_models <- list(
    list("static_wages", 
         c("naive", "ctrls", "cbsa_time", "cbsa_time_het", "dividends"))
  )
  
  for (tab in tab_models) {
    txt <- c(sprintf("<tab:%s>", tab[[1]]))
    
    models <- tab[[2]]
    
    i = 1
    for (stat in c("b", "se", "r2_within", "N")) {
      for (mm in models) {
        
        if (mm == models[1]) {
          row <- est[model == mm & var == "mw_wkp_tot_17_avg"][[stat]]
        } else {
          row <- paste(row, est[model == mm & var == "mw_wkp_tot_17_avg"][[stat]], sep = "\t")
        }
      }
      txt <- c(txt, row)
      i = i + 1
      
      if (i == 3 & tab[[1]] == "static_wages") {     # Add heterogeneity model
        row <- est[model == "cbsa_time_het" 
                   & var == "c.mw_wkp_tot_17_avg##c.std_sh_mw_wkrs_statutory"][["b"]]
        txt <- c(txt, row)
        
        row <- est[model == "cbsa_time_het" 
                   & var == "c.mw_wkp_tot_17_avg##c.std_sh_mw_wkrs_statutory"][["se"]]
        txt <- c(txt, row)
      }
    }
    
    fileConn <- file(file.path(outstub, sprintf("%s.txt", tab[[1]])))
    writeLines(txt, fileConn)
    close(fileConn)
  }
}



main()
