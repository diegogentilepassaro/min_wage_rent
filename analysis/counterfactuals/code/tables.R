remove(list = ls())
library(data.table)

main <- function() {
  instub  <- "../output"
  outstub <- "../output"
  
  dt <- fread(file.path(instub, "data_counterfactuals.csv"))
  
  for (cf in c("fed_9usd", "chi14")) {

      dt_cf <- dt[counterfactual == cf
                  & year == 2020 
                  & cbsa_low_inc_increase == 0]

      txt <- c(sprintf("<tab:counterfactuals_%s>", cf))

      for (sample in c("fully_affected", "no_direct_treatment")) {
      
      dt_sample <- dt_cf[get(sample) == 1]
      
      txt <- c(txt, 
                  paste(dim(dt_sample)[1],
                        median(dt_sample[["d_mw_res"]],         na.rm = T),
                        median(dt_sample[["d_mw_wkp"]],         na.rm = T),
                        median(dt_sample[["s_imputed"]],        na.rm = T),
                        median(dt_sample[["rho_with_imputed"]], na.rm = T),
                        sep = "\t"))
      }

      dt_tot_incidence <- fread(file.path(instub, "tot_incidence.csv"))
      dt_tot_incidence <- dt_tot_incidence[counterfactual == cf]
      txt <- c(txt, 
            paste(dt_tot_incidence$N,
                  dt_tot_incidence$tot_incidence,
                  sep = "\t"))
      
      fileConn <- file(file.path(outstub, sprintf("counterfactuals_%s.txt", cf)))
      writeLines(txt, fileConn)
      close(fileConn)
  }
 
  # Other Federal cfs
  
  txt <- c("<tab:counterfactuals_other>")

  for (cf in c("fed_10pc", "fed_15usd")) {
    dt_cf <- dt[counterfactual == cf
               & year == 2020 
               & cbsa_low_inc_increase == 0]

    for (sample in c("fully_affected", "no_direct_treatment")) {
      
      dt_sample <- dt_cf[get(sample) == 1]      
      txt <- c(txt, 
              paste(dim(dt_sample)[1],
                    median(dt_sample[["d_mw_res"]],         na.rm = T),
                    median(dt_sample[["d_mw_wkp"]],         na.rm = T),
                    median(dt_sample[["s_imputed"]],        na.rm = T),
                    median(dt_sample[["rho_with_imputed"]], na.rm = T),
                    sep = "\t"))
    }
    
    dt_tot_incidence <- fread(file.path(instub, "tot_incidence.csv"))
    dt_tot_incidence <- dt_tot_incidence[counterfactual == cf]
    txt <- c(txt, 
             paste(dt_tot_incidence$N,
                   dt_tot_incidence$tot_incidence,
                   sep = "\t"))
  }
  
  fileConn <- file(file.path(outstub, "counterfactuals_other.txt"))
  writeLines(txt, fileConn)
  close(fileConn)
}


main()
