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
  colnames(zip_lvl_stats) <- c("All U.S. ZIP codes", "Urban US ZIP codes", 
                               "ZIP codes with Zillow SFCC rents", "Baseline panel")
  
  stats_row_labels <- c("Avg population (ACS 2011)", "Avg number of households (ACS 2011)", 
                        "Avg household size (ACS 2011)", "Share of urban ZIP codes", 
                        "Share of renter households (ACS 2011)", 
                        "Share of black population (ACS 2011)",
                        "Share of hispanic population (ACS 2011)", 
                        "Share of households with wage inc. (IRS 2010)",
                        "Share of households with  business inc. (IRS 2010)",
                        "Avg AGI per household (IRS 2010)", 
                        "Avg Wage inc. per household (IRS 2010)",
                        "Avg 40th percentile rent 2br (SAFMR 2012)",
                        "Min residence MW (Feb 2010)",
                        "Avg residence MW (Feb 2010)",
                        "Max residence MW (Feb 2010)",
                        "Number of ZIP codes")
  rownames(zip_lvl_stats) <- stats_row_labels
  
  tab = capture.output(stargazer(zip_lvl_stats, summary = F, digits = 2,
                               type = "latex", float = F))
  tab = gsub("ccccc", "lcccc", tab)
  cat(paste(tab, "\n"), file = "../output/stats_sample.tex")
  
  
  ## ZIP-month stats of baseline panel
  baseline_panel <- fread("../output/baseline_zillow_rents_zipcode_months.csv",
                                          colClasses = c(zipcode = "character")) %>%
    select(zipcode, year_month, actual_mw, ln_mw, exp_ln_mw_17,
           medrentprice_SFCC, medrentpricepsqft_SFCC,ln_rents, 
           medrentprice_2BR, medrentpricepsqft_2BR,
           ln_emp_bizserv, ln_estcount_bizserv, ln_avgwwage_bizserv, 
           ln_emp_info, ln_estcount_info, ln_avgwwage_info, 
           ln_emp_fin, ln_estcount_fin, ln_avgwwage_fin) %>%
    mutate(zipcode = as.factor(zipcode),
           year_month = as.factor(year_month))
  
  var_labels = c("Residence MW", "Ln residence MW", "Workplace ln MW",
                 "Median rent SFCC", "Median rent psqft. SFCC", "Ln median rent psqft. SFCC",
                 "Median rent 2br", "Median rent psqft. 2br",
                 paste0(c("Avg. wage", "Employment", "Estab. count"), " Business serv."),
                 paste0(c("Avg. wage", "Employment", "Estab. count"), " Information serv."), 
                 paste0(c("Avg. wage", "Employment", "Estab. count"), " Financial serv."))
  
  stargazer(baseline_panel, digits = 2,
            omit.summary.stat = c("p25", "p75"), covariate.labels = var_labels,
            #add.lines = list(c("Unique zipcodes", format(length(panel_zipcodes), big.mark = ","), "", "", "", "")),
            float = F, out = "../output/stats_est_panel.tex")
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

main()
