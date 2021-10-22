remove(list = ls())
library(data.table)

main <- function() {
  
  instub  <- "../output/"
  outstub <- "../output/"
  
  est <- fread(file.path(instub, "estimates_all.csv"))
  
  tab_models <- list(
    list("static_wages", 
         c("naive", "ctrls", "cbsa_time", "county_time", "cbsa_time_baseline")),
    list("static_wages_robustness", 
         c("exp_mw_10", "exp_mw_18", "exp_mw_varying", "dividends"))
  )
  
  for (model in tab_models) {
    txt <- c(sprintf("<tab:%s>", model[[1]]))
    
    for (stat in c("b", "se", "r2_within", "N")) {
      for (mm in model[[2]]) {
        
        if (mm == model[[2]][1]) {
          row <- est[model == mm][[stat]]
        } else {
          row <- paste(row, est[model == mm][[stat]], sep = "\t")
        }
      }
      
      txt <- c(txt, row)
    }
    
    fileConn <- file(file.path(outstub, sprintf("%s.txt", model[[1]])))
    writeLines(txt, fileConn)
    close(fileConn)
  }
}



main()
