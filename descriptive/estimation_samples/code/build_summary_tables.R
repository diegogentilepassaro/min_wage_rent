remove(list = ls())
library(dplyr)
source("../../../lib/R/save_data.R")

main <- function() {
  
  ## ZIP level stats
  all_zipcodes      <- load_data("all_zipcode_lvl_data.csv")
  urban_zipcodes    <- load_data("all_urban_zipcode_lvl_data.csv")
  zillow_zipcodes   <- load_data("all_zillow_rents_zipcode_lvl_data.csv")
  baseline_zipcodes <- load_data("baseline_zipcode_lvl_data.csv")

  all_zipcodes_stats      <- build_basic_stats(all_zipcodes)
  urban_zipcodes_stats    <- build_basic_stats(urban_zipcodes)
  zillow_zipcodes_stats   <- build_basic_stats(zillow_zipcodes)
  baseline_zipcodes_stats <- build_basic_stats(baseline_zipcodes)
  
  zip_lvl_stats <- t(rbind(all_zipcodes_stats, urban_zipcodes_stats, 
                           zillow_zipcodes_stats, baseline_zipcodes_stats))
  
  txt <- c("<tab:stats_zip_samples>")
  writeLines(txt, "../output/stats_zip_samples.txt")
  write.table(zip_lvl_stats, "../output/stats_zip_samples.txt", 
              append = TRUE, sep = "\t", dec = ".",
              row.names = FALSE, col.names = FALSE)
  
  ## ZIP-month stats of baseline panel
  baseline_panel <- load_data("baseline_zillow_rents_zipcode_months.csv")
  
  vars_for_table <- c("statutory_mw", "mw_res", "mw_wkp_tot_17",
                      "medrentprice_SFCC", "medrentpricepsqft_SFCC", "ln_rents", 
                      paste0("ln_rents_", c("SF", "CC", "Studio", "1BR", "2BR", "3BR", "Mfr5Plus")), 
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

load_data <- function(filename, instub = "../output") {
  return(data.table::fread(file.path(instub, filename),
                           colClasses = c(zipcode = "character")))
}

build_basic_stats <- function(df) {
  df %>%
    summarise(tot_pop_cens2010              = sum(population_cens2010, na.rm = T)/1000,
              tot_hhlds_cens2010            = sum(n_hhlds_cens2010, na.rm = T)/1000,
              mean_pop_cens2010             = mean(population_cens2010, na.rm = T),
              mean_hhlds_cens2010           = mean(n_hhlds_cens2010, na.rm = T),
              sh_urb_pop_cens2010           = mean(sh_urb_pop_cens2010, na.rm = T),
              sh_hhlds_renteroccup_cens2010 = mean(sh_hhlds_renteroccup_cens2010, na.rm = T),
              sh_black_cens2010             = mean(sh_black_cens2010, na.rm = T),
              sh_white_cens2010             = mean(sh_white_cens2010, na.rm = T),
              share_wage_hhlds_irs2010      = mean(share_wage_hhlds, na.rm = T),
              share_bussiness_hhlds_irs2010 = mean(share_bussiness_hhlds, na.rm = T),
              agi_per_hhld_irs_2010         = mean(agi_per_hhld, na.rm = T)/1000,
              wage_per_hhld_irs2010         = mean(wage_per_hhld, na.rm = T)/1000,
              rent40thperc_2br_safmr2012    = mean(safmr2br, na.rm = T),
              min_binding_mw_feb2010        = min(statutory_mw_feb2010, na.rm = T),
              avg_binding_mw_feb2010        = mean(statutory_mw_feb2010, na.rm = T),
              max_binding_mw_feb2010        = max(statutory_mw_feb2010, na.rm = T),
              min_binding_mw_dec2019        = min(statutory_mw_dec2019, na.rm = T),
              avg_binding_mw_dec2019        = mean(statutory_mw_dec2019, na.rm = T),
              max_binding_mw_dec2019        = max(statutory_mw_dec2019, na.rm = T),
              zip_count                     = n_distinct(zipcode),
              county_count                  = n_distinct(countyfips),
              state_count                   = n_distinct(statefips))
}

build_panel_stats_row <-  function(panel, var){
  panel %>% 
    summarise(across(.cols = all_of(var),
                     .fns  = list(n    = ~ sum(!is.na(.x)), 
                                  mean = ~ mean(.x, na.rm = T), 
                                  sd   = ~ sd(.x, na.rm = T), 
                                  min  = ~ min(.x, na.rm = T), 
                                  max  = ~ max(.x, na.rm = T))))
}


main()
