remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")

load_packages(c("data.table", "usmap"))

main <- function(){
  instub_mw    <- "../../../drive/derived_large/min_wage"
  instub_lodes <- "../../../drive/base_large/lodes"
  outstub      <- "../../../drive/derived_large/min_wage"
  log_file     <- "../output/data_file_manifest.log"
  
  dt.zip <- fread(file.path(instub_mw, "zip_statutory_mw.csv"))
  
  periods <- unique(dt.zip$year_month)
  states  <- fips(c(state.abb, 'DC'))
  
  dts.exp <- lapply(states, function(st) {
      
      dt.od.state <- load_od_matrix(st, instub_lodes)
     
      dt.st <- assemble_expmw_state(st, periods, "actual_mw", dt.zip, dt.od.state)
      
      return(dt.st)
    })
  
  dt.exp_mw <- rbindlist(dts.exp)
  
  save_data(dt.exp_mw, key = c("zipcode", "year", "month"),
            filename = file.path(outstub, "zip_experienced_mw.csv"),
            logfile  = log_file)
  
  save_data(dt.exp_mw, key = c("zipcode", "year", "month"),
            filename = file.path(outstub, "zip_experienced_mw.dta"),
            logfile  = log_file)
}

load_od_matrix <- function(st, instub) {
   
   od <- fread(file.path(instub, paste0('odzip_', st, '.csv')))
   
   od[, c('h_totjob', 'h_job_young', 'h_job_lowinc') := lapply(.SD, sum, na.rm = T) , 
      .SDcols = c('totjob', 'job_young', 'job_lowinc'), 
      by = 'h_zipcode']
   
   setorder(od, h_zipcode, w_zipcode)
   return(od)
}

assemble_expmw_state <- function(x, periods, mw_var, dt.zip, dt.od) {

  # Computes share of treated and experienced MW for every period
   
  dts.period <- lapply(periods, function(y, this_st = dt.od, zip = dt.zip) {
     
   dt.this_date <- zip[year_month == y, ]       # Select given date
   dt.this_date[, w_zipcode := zipcode]         # Create matching variable
   dt.this_date <- dt.this_date[, c("w_zipcode", mw_var, "year_month")]
   
   dt.this_date <- dt.this_date[dt.od, on = 'w_zipcode'] # Merge origin-destination matrix and MW
   
   dt.this_date[, c("sh_tot", "sh_young", "sh_lowinc") := 
                  .((totjob / h_totjob), 
                    (job_young / h_job_young), 
                    (job_lowinc / h_job_lowinc))] #compute share of job for each destination
   
   dt.this_date <- dt.this_date[, 
      .(exp_mw_totjob     = sum(get(mw_var)*sh_totjob, na.rm = T), 
        exp_mw_job_young  = sum(get(mw_var)*sh_job_young, na.rm = T), 
        exp_mw_job_lowinc = sum(get(mw_var)*sh_job_lowinc, na.rm = T)), 
      by = c("h_zipcode", "year_month")
   ]
   
   this_state_date <- this_state_date[!is.na(year_month),] #remove missings
   return(this_state_date)
   
  })
  
  return(rbindlist(dts.period))
}

main()
