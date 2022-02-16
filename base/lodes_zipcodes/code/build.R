remove(list = ls())
library(data.table)
library(stringr)
library(bit64)

source("../../../lib/R/save_data.R")

main <- function() {
  in_lodes <- "../../../drive/raw_data/lodes"
  in_xwalk <- "../../../drive/base_large/census_block_master"
  outstub  <- "../../../drive/base_large/lodes_zipcodes"
  log_file <- "../output/data_file_manifest.log"
  
  dt_xwalk <- load_xwalk(in_xwalk)
  
  #Datasets:
  # Point of View (pov) : statistics for either residents ('rac') or workers ('wac') in given geographies
  # Type (type)         : Job type: Can be all jobs (JT00) or a subset like primary/secondary and private/federal ones
  #                        We always use all jobs
  # Segment (seg)       : Market segment: Can be total (S000), by age, by income, by industry
  #                        We use total jobs
  
  dt.all <- data.table()
  
  for (yy in 2009:2018) {
    
    lodes_wac <- format_lodes(pov    = "wac",    year  = yy,
                              instub = in_lodes, xwalk = dt_xwalk)
    
    lodes_rac <- format_lodes(pov    = "rac",    year  = yy,
                              instub = in_lodes, xwalk = dt_xwalk)
    
    dt <- rbindlist(list(lodes_wac, lodes_rac))
    dt[, year := yy]
    
    dt.all <- rbindlist(list(dt.all, dt))
  }
  
  save_data(dt.all, key = c("zipcode", "year", "jobs_by"),
            filename = file.path(outstub, "jobs.csv"),
            logfile = log_file)
  
  setnames(dt.all, old = names(dt.all),
                   new = gsub("outofstate", "ost", names(dt.all)))
  
  save_data(dt.all, key = c("zipcode", "year", "jobs_by"),
            filename = file.path(outstub, "jobs.dta"),
            nolog = TRUE)
}

load_xwalk <- function(instub) {

  xwalk <- fread(file.path(instub, "census_block_master.csv"),
                 select = c("census_block", "zipcode"),
                 colClasses = c(zipcode = "character"))
  
  setnames(xwalk, old = c("census_block"), 
                  new = c("blockfips"))
  setkey(xwalk, "blockfips")

  return(xwalk)
}

format_lodes <- function(pov, year, instub, xwalk,
                         seg = "S000", type = "JT00") {
  
  if (pov == "wac") geo_name <- "w_geocode"
  if (pov == "rac") geo_name <- "h_geocode"
  
  target_vars <- c("C000", 
                   "CA01", "CA02", "CA03",
                   "CE01", "CE02", "CE03", 
                   "CD01", "CD02", "CD03", "CD04",
                   "CNS05", "CNS07", "CNS10", "CNS18")
  new_varnames <- paste0("jobs_",
                   c("tot",
                     "age_under29",    "age_30to54",     "age_above55",
                     "earn_under1250", "earn_1250_3333", "earn_above3333",
                     "sch_underHS",    "sch_HS_noColl",  "sch_someColl",  "sch_College",
                     "naics_manuf",    "naics_retail",   "naics_finance", "naics_accomm_food"))
  
  files <- list.files(file.path(instub, year, pov, seg, type),
                      full.names = T, pattern = "*.gz")
  files <- files[!grepl("pr", files)]          # Ignore Puerto Rico
  
  dt <- rbindlist(lapply(files, fread, select = c(geo_name, target_vars)))
  
  setnames(dt, old = geo_name, new = "blockfips")
  
  dtzip <- xwalk[dt, on = "blockfips"][, blockfips := NULL]
  dtzip <- dtzip[, lapply(.SD, sum, na.rm = T),
                  .SDcols = new_varnames,
                  by = c("zipcode")]
  
  dtzip <- make_shares(dtzip, new_varnames)
  
  if (pov == "wac") dtzip[, jobs_by := "workplace"]
  if (pov == "rac") dtzip[, jobs_by := "residence"]
  
  return(dtzip)
}

make_shares <- function(dt, vnames) {
  
  vnames      <- vnames[!grepl("tot$", vnames)]
  share_names <- gsub("jobs", "share", vnames)
  
  dt[, (share_names) := lapply(.SD, function(x) x / jobs_tot),
     .SDcols = vnames]
  
  dt[, state_jobs_tot := sum(jobs_tot, na.rm = T),
       by = .(st)]
  
  share_names <- gsub("jobs", "share_outofstate", vnames)
  
  dt[, (share_names) := lapply(.SD, function(x) x / state_jobs_tot),
     .SDcols = vnames][, state_jobs_tot := NULL]
  
  return(dt)
}

# Execute
main()
