remove(list = ls())
library(data.table)

main <- function() {
  instub  <- "../output"
  outstub <- "../output"
  
  dt <- fread(file.path(instub, "data_counterfactuals.csv"))
  
  alpha = 0.35
  
  for (cf in unique(dt$counterfactual)) {
    dt_cf <- dt[counterfactual == cf]

    txt <- c(sprintf("<tab:counterfactuals_%s>", cf),
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
    
    fileConn <- file(file.path(outstub, sprintf("counterfactuals_%s.txt", cf)))
    writeLines(txt, fileConn)
    close(fileConn)
  }
}


main()
