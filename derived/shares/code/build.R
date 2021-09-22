remove(list = ls())
options(scipen=999)

source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")

library("data.table")

main <- function() {
  instub  <- "../../../drive/base_large/lodes"
  outstub <- "../../../drive/derived_large/shares"
  
  fnames_list <- list.files(instub, pattern = "odzip_*", full.names = T)
  
  od_matrix  <- rbindlist(lapply(fnames_list, fread,
                                 colClasses = c("h_zipcode" = "character",
                                                "w_zipcode" = "character")))
  
  dt <- group_matrix_sum(od_matrix)
  
  dt <- compute_shares(dt)

  save_data(dt, key = c("zipcode"),
            filename = file.path(outstub, "zipcode_shares.csv"),
            logfile  = "../output/shares_data_manifest.log")
}

group_matrix_sum <- function(od) {
  
  residents <- od[, .(residents        = sum(totjob), 
                      residents_young  = sum(job_young),
                      residents_lowinc = sum(job_lowinc)),
                  by = "h_zipcode"]
  setnames(residents, "h_zipcode", "zipcode")
  
  
  workers <- od[, .(workers        = sum(totjob), 
                    workers_young  = sum(job_young),
                    workers_lowinc = sum(job_lowinc)),
                by = "w_zipcode"]
  setnames(workers, "w_zipcode", "zipcode")
  
  workers_own_zip <- od[h_zipcode == w_zipcode]
  workers_own_zip <- workers_own_zip[, .(h_zipcode, totjob, job_young, job_lowinc)]
  
  setnames(workers_own_zip, old = c("h_zipcode", "totjob", "job_young", "job_lowinc"),
                            new = c("zipcode", "ownzip_jobs", "ownzip_jobs_young", "ownzip_jobs_lowinc"))
  
  dt <- merge(workers, residents, 
              all.x = T, by = "zipcode")
  dt <- merge(dt, workers_own_zip, 
              all.x = T, by = "zipcode")
  
  return(dt)
}

compute_shares <- function(dt) {
  
  
  dt[, share_residents_young  := residents_young/residents]
  dt[, share_residents_lowinc := residents_lowinc/residents]

  dt[, share_workers_young  := workers_young/workers]
  dt[, share_workers_lowinc := workers_lowinc/workers]
  
  dt[, share_work_same_zip        := ownzip_jobs/residents]
  dt[, share_work_same_zip_young  := ownzip_jobs_young/residents]
  dt[, share_work_same_zip_lowinc := ownzip_jobs_lowinc/residents]
  
  return(dt)
}

# Execute
main() 
