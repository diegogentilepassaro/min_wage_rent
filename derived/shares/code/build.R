remove(list = ls())
options(scipen=999)

source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")

library("data.table")

main <- function() {
  instub  <- "../../../drive/base_large/lodes"
  outstub <- "../../../drive/derived_large/shares"
  
  for (geo in c("zip", "county")) {
    
    if (geo == "zip") {
      patt  = "odzip_*"
      h_geo = "h_zipcode"
      w_geo = "w_zipcode"
      key_  = "zipcode"
    } else {
      patt = "odcounty*"
      h_geo = "h_countyfips"
      w_geo = "w_countyfips"
      key_  = "county"
    }

    fnames_list <- list.files(instub, pattern = patt, full.names = T)
    
    od_matrix  <- rbindlist(lapply(fnames_list, fread,
                                  colClasses = c(h_geo = "character",
                                                 w_geo = "character")))
    
    dt <- group_matrix_sum(od_matrix, key_, h_geo, w_geo)
    
    dt <- compute_shares(dt)

    save_data(dt, key = c(key_),
              filename = file.path(outstub, paste0(key_, "_shares.csv")),
              logfile  = "../output/shares_data_manifest.log")
  }
}

group_matrix_sum <- function(od, key_, h_geo, w_geo) {
  
  residents <- od[, .(residents        = sum(totjob), 
                      residents_young  = sum(job_young),
                      residents_lowinc = sum(job_lowinc)),
                  by = h_geo]
  setnames(residents, h_geo, key_)
  
  
  workers <- od[, .(workers        = sum(totjob), 
                    workers_young  = sum(job_young),
                    workers_lowinc = sum(job_lowinc)),
                by = w_geo]
  setnames(workers, w_geo, key_)
  
  workers_own_zip <- od[get(h_geo) == get(w_geo)]
  vars <- c(h_geo, w_geo, "totjob", "job_young", "job_lowinc")
  workers_own_zip <- workers_own_zip[, ..vars]
  
  setnames(workers_own_zip, old = c(h_geo, "totjob",   "job_young",      "job_lowinc"),
                            new = c(key_,  "own_jobs", "own_jobs_young", "own_jobs_lowinc"))
  
  dt <- merge(workers, residents, 
              all.x = T, by = key_)
  dt <- merge(dt, workers_own_zip, 
              all.x = T, by = key_)
  
  return(dt)
}

compute_shares <- function(dt) {
  
  
  dt[, share_residents_young  := residents_young/residents]
  dt[, share_residents_lowinc := residents_lowinc/residents]

  dt[, share_workers_young  := workers_young/workers]
  dt[, share_workers_lowinc := workers_lowinc/workers]
  
  dt[, share_work_samegeo        := own_jobs/residents]
  dt[, share_work_samegeo_young  := own_jobs_young/residents]
  dt[, share_work_samegeo_lowinc := own_jobs_lowinc/residents]
  
  return(dt)
}

# Execute
main() 
