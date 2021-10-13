remove(list = ls())
options(scipen=999)

source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")

library("data.table")

main <- function() {
  instub  <- "../../../drive/base_large/lodes_od"
  outstub <- "../../../drive/derived_large/shares"
  
  for (geo in c("zip", "county")) {
    
    if (geo == "zip") {
      patt  = "odzip_*"
      h_geo = "r_zipcode"
      w_geo = "w_zipcode"
      key_  = "zipcode"
    } else {
      patt = "odcounty*"
      h_geo = "r_countyfips"
      w_geo = "w_countyfips"
      key_  = "county"
    }
    
    dt <- data.table()
    
    for (yy in 2009:2018) {
      od_files <- list.files(file.path(instub, yy), pattern = patt, full.names = T)
      od_files <- add_missing_state_years(od_files, instub, geo, yy)
      
      od_matrix  <- rbindlist(lapply(od_files, fread,
                                     colClasses = c(h_geo = "character",
                                                    w_geo = "character")))
      
      dt.year <- group_matrix_sum(od_matrix, key_, h_geo, w_geo)
      
      dt.year <- compute_shares(dt.year)
      dt.year[, year := yy]
      dt.year <- dt.year[!duplicated(dt.year$zipcode)]
      
      dt <- rbindlist(list(dt, dt.year))
    }
    
    save_data(dt, key = c(key_, "year"),
              filename = file.path(outstub, paste0(key_, "_shares.csv")),
              logfile  = "../output/shares_data_manifest.log")
  }
}

add_missing_state_years <- function(od_files, instub, geo, yy) {
  
  if (geo == "countyfips") geo <- "county"
  else                     geo <- "zip"
  
  if (yy == 2009) {
    return(c(od_files, sprintf("%s/2010/od%s_11.csv", instub, geo), 
             sprintf("%s/2011/od%s_25.csv", instub, geo)))
  } else if (yy == 2010) {
    return(c(od_files, sprintf("%s/2011/od%s_25.csv", instub, geo)))
  } else if (yy %in% c(2017, 2018)) {
    return(c(od_files, sprintf("%s/2016/od%s_02.csv", instub, geo)))
  } else {
    return(od_files)
  }
}

group_matrix_sum <- function(od, key_, h_geo, w_geo) {
  
  residents <- od[, .(residents        = sum(jobs_tot), 
                      residents_young  = sum(jobs_age_under29),
                      residents_lowinc = sum(jobs_earn_under1250)),
                  by = h_geo]
  setnames(residents, h_geo, key_)
  
  
  workers <- od[, .(workers        = sum(jobs_tot), 
                    workers_young  = sum(jobs_age_under29),
                    workers_lowinc = sum(jobs_earn_under1250)),
                by = w_geo]
  setnames(workers, w_geo, key_)
  
  workers_own_zip <- od[get(h_geo) == get(w_geo)]
  vars <- c(h_geo, w_geo, "jobs_tot", "jobs_age_under29", "jobs_earn_under1250")
  workers_own_zip <- workers_own_zip[, ..vars]
  
  setnames(workers_own_zip, old = c(h_geo, "jobs_tot",   "jobs_age_under29",      "jobs_earn_under1250"),
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