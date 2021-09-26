remove(list = ls())

library(data.table)
library(stringr)
library(bit64)

source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")
source("make_xwalk.R")


main <- function() {
  in_lodes       <- '../../../drive/raw_data/lodes'
  in_xwalk_lodes <- '../../../raw/crosswalk/lodes'
  in_xwalk       <- '../../geo_master/output'
  outdir         <- '../../../drive/base_large/lodes_area_charac'
  log_file       <- '../output/data_file_manifest.log'
  
  xwalk <- make_xwalk_raw_wac(in_xwalk_lodes)
  
  tract_zip_xwalk <- fread(file.path(in_xwalk, "tract_zip_master.csv"), 
                           colClasses = c("tract_fips" = "numeric", "zipcode" = "character", "res_ratio" = "numeric"))
  
  #Datasets:
  # Point of View (pov) : statistics for either residents ('rac') or workers ('wac') in given geographies
  # Type (type)         : Job type: Can be all jobs (JT00) or a subset like primary/secondary and private/federal ones
  #                        We always use all jobs
  # Segment (seg)       : Market segment: Can be total (S000), by age, by income, by industry
  #                        We use total jobs
  
  dt.all <- data.table()
  
  for (yy in 2009:2018) {
    # Zipcode as workplace: all workers
    lodes_wac <- format_lodes(pov         = 'wac',
                              year        = yy,
                              instub      = in_lodes,
                              xw          = xwalk,
                              xw_tractzip = tract_zip_xwalk)
    
    # Zipcode as residence: all workers
    lodes_rac <- format_lodes(pov         = 'rac',
                              year        = yy,
                              instub      = in_lodes, 
                              xw          = xwalk, 
                              xw_tractzip = tract_zip_xwalk)
    
    dt <- rbindlist(list(lodes_wac, lodes_rac))
    dt[, year := yy]
    
    dt.all <- rbindlist(list(dt.all, dt))
  }
  
  save_data(dt.all, key = c('zipcode', 'year', 'jobs_by'),
            filename = file.path(outdir, 'jobs.csv'),
            logfile = log_file)
  
  setnames(dt.all, old = names(dt.all),
                   new = gsub("outofstate", "ost", names(dt.all)))
  
  save_data(dt.all, key = c('zipcode', 'year', 'jobs_by'),
            filename = file.path(outdir, 'jobs.dta'),
            nolog = TRUE)
}

format_lodes <- function(pov, year, instub, xw, xw_tractzip,
                         seg = 'S000', type = 'JT00') {
  
  if      (pov == 'rac') geo_name <- 'h_geocode'
  else if (pov == 'wac') geo_name <- 'w_geocode'
  
  target_vars <- c('C000', 
                   'CA01', 'CA02', 'CA03',
                   'CE01', 'CE02', 'CE03', 
                   'CD01', 'CD02', 'CD03', 'CD04',
                   'CNS05', 'CNS07', 'CNS10', 'CNS18')
  new_names    <- c('jobs_tot',
                    'jobs_age_under29',    'jobs_age_30to54',     'jobs_age_above55',
                    'jobs_earn_under1250', 'jobs_earn_1250_3333', 'jobs_earn_above3333',
                    'jobs_sch_underHS',    'jobs_sch_HS_noColl',  'jobs_sch_someColl',  'jobs_sch_College',
                    'jobs_naics_manuf',    'jobs_naics_retail',   'jobs_naics_finance', 'jobs_naics_accomm_food')
  
  files <- list.files(file.path(instub, year, pov, seg, type),
                      full.names = T, pattern = "*.gz")
  files <- files[!grepl("pr", files)]          # Ignore Puerto Rico
  
  dt <- rbindlist(lapply(files, fread, select = c(geo_name, target_vars)))
  
  setnames(dt, old = c(geo_name, target_vars),
               new = c('blockfips', new_names))
  dt[, blockfips := as.numeric(blockfips)]
  
  dttract <- xw[dt, on = 'blockfips'][, 'blockfips':= NULL]
  dttract <- dttract[, lapply(.SD, sum, na.rm = T),
                    by = c('tract_fips', 'st')]
  
  dtzip <- dttract[xw_tractzip, on = 'tract_fips']
  
  dtzip <- dtzip[, lapply(.SD, function(x, w) sum(x*w, na.rm = T), w = res_ratio), 
                  by = c('zipcode', 'st'), .SDcols = new_names]
  
  dtzip <- make_shares(dtzip, new_names)
  
  if      (pov == 'rac') dtzip[, jobs_by := "residence"]
  else if (pov == 'wac') dtzip[, jobs_by := "workplace"]
  
  dtzip <- dtzip[!is.na(st)]                       # Drop some unintentionally duplicated zip codes
  dtzip <- dtzip[!(zipcode == "75501" & st == 5)]  # For some reason this Texas zipcode also appears in Arkansas
  
  return(dtzip)
}

make_shares <- function(dt, vnames) {
  
  vnames      <- vnames[!grepl("tot$", vnames)]
  share_names <- gsub("jobs", "share", vnames)
  
  dt[, (share_names) := lapply(.SD, function(x) x / get("jobs_tot")),
     .SDcols = vnames]
  
  dt[, state_jobs_tot := sum(jobs_tot, na.rm = T),
         by = 'st']
  
  share_names <- gsub("jobs", "share_outofstate", vnames)
  
  dt[, (share_names) := lapply(.SD, function(x) x / get("state_jobs_tot")),
     .SDcols = vnames][, state_jobs_tot := NULL]
  
  return(dt)
}


# Execute
main()
