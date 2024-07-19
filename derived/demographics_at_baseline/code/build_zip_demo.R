remove(list = ls())

library(data.table)
source("../../../lib/R/save_data.R")

setDTthreads(18)

main <- function(){
  in_master <- "../../../drive/base_large/census_block_master"
  in_demo   <- "../../../drive/derived_large/demographics_at_baseline"
  outstub   <- "../../../drive/derived_large/demographics_at_baseline"
  log_file  <- "../output/zip_data_manifest.log"

  dt_geo <- fread(file.path(in_master, "census_block_master.csv"),
                  select = list(character = c("block", "tract", "zcta", "zipcode"),
                                numeric   = c("num_house10")))

  dt_zip_demo  <- block_to_zip(in_demo, copy(dt_geo), "zipcode")
  dt_zip_mwers <- tract_to_zip(in_demo, copy(dt_geo), "zipcode")

  dt_zip <- merge(dt_zip_demo, dt_zip_mwers, by = c("zipcode"), all = T)
  rm(dt_zip_demo, dt_zip_mwers)

  dt_zip <- compute_shares(dt_zip)

  save_data(dt_zip, key  = c("zipcode"),
            filename = file.path(outstub, "zipcode.dta"),
            logfile  = log_file)
  fwrite(dt_zip,
         file = file.path(outstub, "zipcode.csv"))

  dt_zcta_demo  <- block_to_zip(in_demo, copy(dt_geo), "zcta")
  dt_zcta_mwers <- tract_to_zip(in_demo, copy(dt_geo), "zcta")
  rm(dt_geo)

  dt_zcta <- merge(dt_zcta_demo, dt_zcta_mwers, by = c("zcta"), all = T)

  dt_zcta <- compute_shares(dt_zcta)

  save_data(dt_zcta, key  = c("zcta"),
            filename = file.path(outstub, "zcta.dta"),
            logfile  = log_file)
  fwrite(dt_zcta,
         file = file.path(outstub, "zcta.csv"))
}

block_to_zip <- function(instub, dt_geo, zipvar) {
  
  dt <- fread(file.path(instub, "block.csv"),
              colClasses = c(block   = "character"))

  dt <- dt_geo[dt,  on = c("block")]

  dt <- dt[zipvar != ""]

  dt <- dt[, .(population_cens2010          = sum(population,              na.rm = T),
               n_male_cens2010              = sum(n_male,                  na.rm = T),
               n_white_cens2010             = sum(n_white,                 na.rm = T),
               n_black_cens2010             = sum(n_black,                 na.rm = T),
               urb_pop_cens2010             = sum(urban_population,        na.rm = T),
               n_hhlds_cens2010             = sum(n_hhlds,                 na.rm = T),
               n_hhlds_urban_cens2010       = sum(n_hhlds_urban,           na.rm = T),
               n_hhlds_renteroccup_cens2010 = sum(n_hhlds_renter_occupied, na.rm = T)),
           by = c(zipvar)]

  dt <- dt[, rural_pop_cens2010 := population_cens2010 - urb_pop_cens2010]
  
  return(dt)
}

tract_to_zip <- function(instub, dt_geo, zipvar) {
  
  # Tract-to-zip crosswalk
  dt_geo <- dt_geo[, .(num_house10 = sum(num_house10)),
                   by = c("tract", zipvar)]

  # Make zipcode level dataset
  vars = c("population", "n_workers", "med_hhld_inc",
           "n_mw_workers_statutory", "n_mw_workers_state", "n_mw_workers_fed")

  dt <- fread(file.path(instub, "tract.csv"),
              colClasses = c(tract = "character"))

  dt <- dt_geo[dt,  on = c("tract")]
  dt <- dt[zipvar != ""]
  
  # Assign var to each zip code
  dt[, share_in_zip := num_house10/sum(num_house10),
      by = .(tract)]
  for (var in vars) {
    dt[, c(var) := round(share_in_zip*get(var))]
  }

  dt <- dt[, .(population_acs2014     = sum(population),
               n_workers_acs2014      = sum(n_workers),
               n_mw_wkrs_statutory    = sum(n_mw_workers_statutory),
               n_mw_wkrs_state        = sum(n_mw_workers_state),
               n_mw_wkrs_fed          = sum(n_mw_workers_fed),
               med_hhld_inc_acs2014   = weighted.mean(med_hhld_inc, num_house10)),
           by = c(zipvar)]

  return(dt)
}

compute_shares <- function(dt) {
  
  # Census 2010
  for (var in paste0(c("n_white", "n_black", "n_male", "urb_pop", "rural_pop"), "_cens2010")) {

    newvar <- gsub("^n_", "sh_", var)
    if (grepl("pop", var)) newvar <- paste0("sh_", var)

    dt[, c(newvar) := get(var)/population_cens2010]
  }
  for (var in paste0(c("n_hhlds_urban", "n_hhlds_renteroccup"), "_cens2010")) {
    newvar <- gsub("^n_", "sh_", var)
    dt[, c(newvar) := get(var)/n_hhlds_cens2010]
  }
  
  # ACS 2014
  for (var in paste0("n_mw_wkrs_", c("statutory", "state", "fed"))) {
    newvar <- gsub("^n_", "sh_", var)
    dt[, c(newvar) := get(var)/n_workers_acs2014]
  }
  
  return(dt)
}

main()
