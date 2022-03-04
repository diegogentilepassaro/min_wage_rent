remove(list = ls())

library(data.table)
source("../../../lib/R/save_data.R")

setDTthreads(20)

main <- function(){
  in_master <- "../../../drive/base_large/census_block_master"
  in_census <- "../../../drive/base_large/demographics"
  outstub   <- "../../../drive/derived_large/demographics_at_baseline"
  log_file  <- "../output/data_file_manifest.log"

  dt <- fread(file.path(in_master, "census_block_master.csv"),
              select = list(character = c("block")))
  dt_census <- fread(file.path(in_census, "census_cb_2010.csv"),
                  colClasses =  c("block" = "character"))
  dt <- merge(dt, dt_census, all.x = TRUE)
  
  dt <- dt[, share_male         := n_male/population]
  dt <- dt[, share_white        := n_white/population]
  dt <- dt[, share_black        := n_black/population]
  dt <- dt[, share_urban        := urban_population/population]
  dt <- dt[, share_renter_hhlds := n_hhlds_renter_occupied/n_hhlds]
  
  dt <- dt[, c("block", "population", "n_hhlds", 
               "n_male", "share_male", "n_white", "share_white",
               "n_black", "share_black", "urban_population", "share_urban", 
               "n_hhlds_renter_occupied", "share_renter_hhlds")]
  
  save_data(dt,
            key      = c("block"),
            filename = file.path(outstub, "block_demo_baseline.dta"),
            logfile  = log_file)
  fwrite(dt,
         file = file.path(outstub, "block_demo_baseline.csv"))
}

main()
