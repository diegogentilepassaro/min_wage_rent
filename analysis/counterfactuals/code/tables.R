remove(list = ls())
library(data.table)

main <- function() {
  instub  <- "../output"
  outstub <- "../output"
  
  dt <- fread(file.path(instub, "data_counterfactuals.csv"))
  
  alpha = 0.35
  
  txt <- c("<tab:counterfactuals>",
           paste(alpha - 0.1, alpha + 0.1, sep = "\t"))
  
  for (sample in c("fully_affected", "no_direct_treatment")) {
    
    dt_sample <- dt[get(sample) == 1]
    
    txt <- c(txt, 
             paste(dim(dt_sample)[1],
                   mean(dt_sample[["d_ln_mw"]],         na.rm = T),
                   mean(dt_sample[["d_exp_ln_mw_17"]],  na.rm = T),
                   mean(dt_sample[["ratio_increases"]], na.rm = T),
                   mean(dt_sample[["rho_lb"]],          na.rm = T),
                   mean(dt_sample[["rho_ub"]],          na.rm = T),
                   sep = "\t"))
    
  }
  
  fileConn <- file(file.path(outstub, "counterfactuals.txt"))
  writeLines(txt, fileConn)
  close(fileConn)
}


main()
