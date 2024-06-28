remove(list = ls())
library(data.table)

source('../../../lib/R/save_data.R')

main <- function() {
  instub  <- '../../../drive/raw_data/acs_rents'
  outstub <- '../../../drive/base_large/acs_rents'
  
  folder_names <- list.files(instub, pattern = "B2*")
  
  # These data are aggregated at the block group level
  ## Need to use a crosswalk to aggregate
  folder_names <- folder_names[folder_names != "gross_rent_as_a_percentage"]
  
  for (folder_name in folder_names) {
    dt <- make_data_folder(instub, folder_name)

    if (folder_name == folder_names[1]) {
      dt_all <- dt
    } else {
      dt_all <- merge(dt_all, dt, by=c("geo_id", "zcta", "year"))
    }
  }
  
  save_data(dt_all, key = c("geo_id", "zcta", "year"),
            filename = file.path(outstub, "zcta_year.csv"),
            logfile  = "../output/data_file_manifest.log")
}

make_data_folder <- function(instub, folder) {
  in_data <- file.path(instub, folder)
  
  new_varname <- get_new_varname(folder)
  
  data_files <- list.files(in_data, pattern = "Data.csv")
  
  dt <- data.table()
  
  for (ff in data_files) {
    yyyy        <- get_year(ff)
    
    dat <- fread(file.path(in_data, ff), header = T)
    
    dat <- dat[GEO_ID != "Geography"] # Remove description of variables
    
    old_varname <- get_old_varname(ff, names(dat))
    
    dat <- dat[, .SD, .SDcols = c("GEO_ID", "NAME", old_varname)]
    
    setnames(dat, new = c("geo_id", "zcta", new_varname))
    
    dat[, zcta := gsub("ZCTA5", "", zcta)]
    
    dat[grepl("-", get(new_varname)), 
        c(new_varname) := NA]
    
    dat[, c(new_varname) := as.numeric(get(new_varname))]
    
    dat[, year := yyyy]
    
    dt <- rbindlist(list(dt, dat))
  }
  
  return(dt)
}

get_year <- function(folder_name) {
  matches <- regexpr("Y(\\d{4})\\.", folder_name) 
  yyyy    <- regmatches(folder_name, matches)
  
  return(as.numeric(gsub("Y|\\.", "", yyyy)))
}

get_old_varname <- function(folder_name, all_vars) {
  
  matches <- regexpr("B(\\d{5})\\-", folder_name) 
  varname <- regmatches(folder_name, matches)
  varname <- gsub("\\-", "", varname)
  
  position <- grepl(varname, all_vars) & grepl("001E", all_vars)
  
  return(all_vars[position])
}

get_new_varname <- function(folder_name) {
  
  if (grepl("lower_contract_rent", folder_name)) {
    
    return("rent_p25")
  } else if (grepl("median_contract_rent", folder_name)) {
    
    return("rent_median")
  } else if (grepl("upper_contract_rent", folder_name)) {
    
    return("rent_p75")
  } else if (grepl("aggregate_contract_rents", folder_name)) {
    
    return("rent_aggregate")
  } else if (grepl("gross_rent_as_a_percentage", folder_name)) {
    
    return("rent_share_hh_income")
  } else if (grepl("contract_rent", folder_name)) {
    
    return("renter_occ_housing_units")
  }
}


main()
