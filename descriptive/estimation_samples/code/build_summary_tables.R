remove(list = ls())
source("../../../lib/R/save_data.R")

library(data.table)
library(dplyr)

main <- function() {
  
  ## ZIP level stats
  all_zipcodes <- fread("../output/all_zipcode_lvl_data.csv",
                  colClasses = c(zipcode = "character"))
  all_urban_zipcodes <- fread("../output/all_urban_zipcode_lvl_data.csv",
                        colClasses = c(zipcode = "character"))
  all_zillow_rents_zipcodes <- fread("../output/all_zillow_rents_zipcode_lvl_data.csv",
                              colClasses = c(zipcode = "character"))
  baseline_zillow_rents_zipcodes <- fread("../output/baseline_zillow_rents_zipcode_lvl_data.csv",
                                     colClasses = c(zipcode = "character"))

  all_zipcodes_stats   <- build_basic_stats(all_zipcodes)
  all_urban_zipcodes_stats <- build_basic_stats(all_urban_zipcodes)
  all_zillow_rents_zipcodes_stats <- build_basic_stats(all_zillow_rents_zipcodes)
  baseline_zillow_rents_zipcodes_stats   <- build_basic_stats(baseline_zillow_rents_zipcodes)
  
  zip_lvl_stats <- rbind(all_zipcodes_stats, all_urban_zipcodes_stats, 
                 all_zillow_rents_zipcodes_stats, baseline_zillow_rents_zipcodes_stats)
  zip_lvl_stats <- t(zip_lvl_stats)
  
  txt <- c("<tab:stats_zip_samples>")
  writeLines(txt, "../output/stats_zip_samples.txt")
  write.table(zip_lvl_stats, "../output/stats_zip_samples.txt", 
              append = TRUE, sep = "\t", dec = ".",
              row.names = FALSE, col.names = FALSE)
  
  
  ## ZIP-month stats of baseline panel
  baseline_panel <- fread("../output/baseline_zillow_rents_zipcode_months.csv",
                                          colClasses = c(zipcode = "character"))
  
  vars_for_table <- c("actual_mw", "ln_mw", "exp_ln_mw_17",
                      "medrentprice_SFCC", "medrentpricepsqft_SFCC", "ln_rents", 
                      "medrentprice_2BR", "medrentpricepsqft_2BR",
                      "ln_emp_bizserv", "ln_estcount_bizserv", "ln_avgwwage_bizserv", 
                      "ln_emp_info", "ln_estcount_info", "ln_avgwwage_info", 
                      "ln_emp_fin", "ln_estcount_fin", "ln_avgwwage_fin")

  txt <- c("<tab:stats_est_panel>")
  writeLines(txt, "../output/stats_est_panel.txt")
  for (var in vars_for_table) {
   var_row <- build_panel_stats_row(baseline_panel, var)
   write.table(var_row, "../output/stats_est_panel.txt", 
               append = TRUE, sep = "\t", dec = ".",
               row.names = FALSE, col.names = FALSE)
  }
}

build_basic_stats <- function(df) {
  stats <- df %>%
    summarise(population_acs2011              = mean(population, na.rm = T),
              households_acs2011              = mean(total_households, na.rm = T),
              hhld_size_acs_2011              = mean(hhld_size, na.rm = T),
              urb_zip_share_geo_master        = 1 - mean(rural, na.rm = T),
              share_renter_hhlds_acs2011      = mean(share_renter_hhlds, na.rm = T),
              share_black_pop_acs2011         = mean(share_black_pop, na.rm = T),
              share_hispanic_pop_acs2011      = mean(share_hispanic_pop, na.rm = T),
              share_wage_hhlds_irs2010        = mean(share_wage_hhlds, na.rm = T),
              share_bussiness_hhlds_irs2010   = mean(share_bussiness_hhlds, na.rm = T),
              agi_per_hhld_irs_2010           = mean(agi_per_hhld, na.rm = T),
              wage_per_hhld_irs2010           = mean(wage_per_hhld, na.rm = T),
              rent40thperc_2br_safmr2012      = mean(safmr2br, na.rm = T),
              min_binding_mw_feb2010          = min(actual_mw, na.rm = T),
              avg_binding_mw_feb2010          = mean(actual_mw, na.rm = T),
              max_binding_mw_feb2010          = max(actual_mw, na.rm = T),
              zip_count                       = n_distinct(zipcode))
  return(stats)
}


build_panel_stats_row <-  function(panel, var){
  panel_stats_row <- panel %>% 
    summarise(across(.cols = var, 
                     .fns=list(n =  ~ sum(!is.na(.x)), 
                               mean = ~ mean(.x, na.rm = T), 
                               sd = ~ sd(.x, na.rm = T), 
                               min = ~ min(.x, na.rm = T), 
                               max = ~ max(.x, na.rm = T))))
  return(panel_stats_row)
}

main()
