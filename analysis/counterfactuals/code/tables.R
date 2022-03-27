remove(list = ls())
library(data.table)

main <- function() {
  instub  <- "../output"
  outstub <- "../output"
  
  dt <- fread(file.path(instub, "data_counterfactuals.csv"))
  
  alpha = 0.35

  dt_cf <- dt[counterfactual == "fed_9usd"]

  txt <- c("<tab:counterfactuals_fed_9usd>",
            paste(alpha - 0.1, alpha + 0.1, sep = "\t"))

  for (sample in c("fully_affected", "no_direct_treatment")) {
    
    dt_sample <- dt_cf[get(sample) == 1]
    
    txt <- c(txt, 
            paste(dim(dt_sample)[1],
                  mean(dt_sample[["d_mw_res"]],  na.rm = T),
                  mean(dt_sample[["d_mw_wkp"]],  na.rm = T),
                  mean(dt_sample[["rho_lb"]],    na.rm = T),
                  mean(dt_sample[["rho_ub"]],    na.rm = T),
                  sep = "\t"))
  }
  
  fileConn <- file(file.path(outstub, "counterfactuals_fed_9usd.txt"))
  writeLines(txt, fileConn)
  close(fileConn)

  txt <- c("<tab:counterfactuals_other>",
            paste(alpha - 0.1, alpha + 0.1, sep = "\t"))

  for (cf in c("fed_10pc", "fed_15usd")) {
    dt_cf <- dt[counterfactual == cf]

    for (sample in c("fully_affected", "no_direct_treatment")) {
      
      dt_sample <- dt_cf[get(sample) == 1]      
      txt <- c(txt, 
              paste(dim(dt_sample)[1],
                    mean(dt_sample[["d_mw_res"]],  na.rm = T),
                    mean(dt_sample[["d_mw_wkp"]],  na.rm = T),
                    mean(dt_sample[["rho_lb"]],    na.rm = T),
                    mean(dt_sample[["rho_ub"]],    na.rm = T),
                    sep = "\t"))
    }    
  }
  
  fileConn <- file(file.path(outstub, "counterfactuals_other.txt"))
  writeLines(txt, fileConn)
  close(fileConn)
}


main()
