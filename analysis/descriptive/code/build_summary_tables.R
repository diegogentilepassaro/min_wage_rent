remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")

load_packages(c('readr', 'readxl', 'haven', 'dplyr', 'stringr', 'stargazer'))


main <- function() {
  instub_base_l <- "../../../drive/base_large/output"
  instub_derv_l <- "../../../drive/derived_large/output"
  instub_cbsa   <- "../../../drive/raw_data/census/cbsa/nhgis0049_csv"
  instub_xwalk  <- "../../../raw/crosswalk"
  outstub       <- "../output/"
  
  rent_vars <- paste0("medrentpricepsqft", c("_2br", "_mfr5plus", "_sfcc"))
  
  df_zipdemo <- read_csv(file.path(instub_base_l, "zip_demo.csv"))
    
  df_cbsa    <- load_top_CBSA(df_zipdemo, instub_cbsa, instub_xwalk)
  
  df_rents_panel <- load_rents(df_zipdemo, instub_derv_l, rent_vars)
  df_rents_all   <- load_rents(df_zipdemo, instub_derv_l, rent_vars, all = T)
  
  panel_zipcodes  <- unique(df_rents_panel$zipcode)
  zillow_zipcodes <- unique(df_rents_all %>% 
                              filter(!is.na(medrentpricepsqft_sfcc)) %>%
                              pull(zipcode))
  
  # Compare our sample to full US and urban US
  US_stats   <- build_basic_stats(df_zipdemo)
  CBSA_stats <- build_basic_stats(df_cbsa)
  rents_panel_stats <- build_basic_stats(df_zipdemo %>% filter(zipcode %in% panel_zipcodes))
  rents_all_stats   <- build_basic_stats(df_zipdemo %>% filter(zipcode %in% zillow_zipcodes))
  
  stats <- rbind(US_stats, CBSA_stats, rents_all_stats, rents_panel_stats)
  
  stats <- add_basic_rents_and_format(stats, df_rents_panel, df_rents_all, rent_vars[3])
  
  row_labels <- c("Population (millions) (2010)", "Population as share of U.S.", 
                  "Housing Units (millions) (2010)", "Housing Units as share of U.S.", 
                  paste0(c("Urban", "College", "African-American", "Hispanic", "Elder",
                           "Poor", "Unemployed"), " Share (2010)"),
                  "Mean HH income (2010)", "Rent House Share (2010)", 
                  "Work in same county share (2010)", "Unique zipcodes", 
                  paste0("Share of ", c("state ", "county ", " local"), "events"), 
                  paste0(c("Mean ", "Unique zipcodes "), "SFCC psqft rent"))
  rownames(stats) <- row_labels
  
  stargazer(stats, summary = F, digits = 2,
            float = F, out = file.path(outstub, "stats_sample.tex"))
  
  # Statistics of estimating panel
  df_est <- as.data.frame(df_rents_panel %>% 
                            select(c("zipcode", "year_month", rent_vars, "medrentprice_sfcc",
                                     "estcount_servpr", "avgwwage_servpr", "emp_servpr")) %>%
                            mutate(zipcode = as.factor(zipcode),
                                   year_month = as.factor(year_month)))
  
  var_labels = c(paste0("Median rent price per sqft.", c(" 2BR", " MFR5plus", "SFCC")), "Median rent price SFCC",
                 paste0(c("Establishment count", "Average wage", "Employment"), " Services"))
  
  stargazer(df_est, digits = 2,
            omit.summary.stat = c("p25", "p75"), covariate.labels = var_labels,
            #add.lines = list(c("Unique zipcodes", format(length(panel_zipcodes), big.mark = ","), "", "", "", "")),
            float = F, out = file.path(outstub, "stats_est_panel.tex"))
}

load_top_CBSA <- function(df_zipdemo, instub_cbsa, instub_xwalk, n = 100) {
  
  zip_cbsa <- read_excel(file.path(instub_xwalk, "ZIP_CBSA_122019.xlsx"),
                         col_types = "numeric") %>%
    rename(zipcode = ZIP, cbsa = CBSA, totratio = TOT_RATIO) %>%
    select(zipcode, cbsa, totratio)
  
  df <- left_join(zip_cbsa, df_zipdemo) %>%
    filter(totratio > 0.5) %>%
    group_by(cbsa) %>%
    mutate(pop_cbsa = sum(pop2010)) %>%
    ungroup()
  
  pop_cbsa <- read_csv(file.path(instub_cbsa, "nhgis0049_ds172_2010_cbsa.csv")) %>%
    rename(pop_cbsa = H7V001, cbsa = CBSAA) %>%
    select(pop_cbsa, cbsa) %>% arrange(-pop_cbsa) %>%
    mutate(topn = ifelse(row_number() <= n, 1, 0))
  
  df <- left_join(df, pop_cbsa[, c("cbsa", "topn")])
  
  return(df %>% filter(topn == 1))
}

load_rents <- function(df_zipdemo, instub, rent_vars, all = F) {
  
  if (all) {
    df_rents <- read_dta(file.path(instub, "zipcode_yearmonth_panel_all.dta")) %>%
      select(c("zipcode", "year_month", "year", "month", rent_vars, "medrentprice_sfcc",
               "state_event", "county_event", "local_event"))
  } else {
    df_rents <- read_dta(file.path(instub, "baseline_rent_panel.dta"))
    
    cpi      <- read_csv(file.path("../../../drive/raw_data/bls", "cpi_bls.csv")) %>%
      mutate(Period = as.numeric(str_replace(Period, "M", ""))) %>%
      rename(year = Year, month = Period, cpi = Value) %>%
      filter(year != 2020) %>% select(year, month, cpi) %>%
      mutate(cpi = cpi/last(cpi))    # Bring everything to Dec 2019 prices
    
    df_rents <- left_join(df_rents, cpi, by = c('year', 'month'))
    for (var in rent_vars){
      df_rents[, var] <- df_rents[, var]/df_rents$cpi
    }
    df_rents <- df_rents %>% mutate(cpi = NULL)
  }
  
  return(df_rents)
}


build_basic_stats <- function(df) {
  
  stats <- df %>%
    summarise(pop_2010            = sum(pop2010, na.rm = T)/1e6,
              housing_units_2010  = sum(housing_units2010, na.rm = T)/1e6,
              urb_share2010       = mean(urb_share2010, na.rm = T),
              college_share2010   = mean(urb_share2010, na.rm = T),
              poor_share20105     = mean(urb_share2010, na.rm = T),
              black_share2010     = mean(urb_share2010, na.rm = T),
              hisp_share2010      = mean(hisp_share2010, na.rm = T),
              elder_share2010     = mean(elder_share2010, na.rm = T),
              unemp_share20105    = mean(unemp_share20105, na.rm = T),
              med_hhinc20105      = mean(med_hhinc20105, na.rm = T),
              renthouse_share2010 = mean(renthouse_share2010, na.rm = T),
              work_county_share20105 = mean(work_county_share20105, na.rm = T),
              zip_count           = n_distinct(zipcode))
  
  return(stats)
}

add_basic_rents_and_format <- function(stats, df_rents_panel, df_rents_all, rent_var) {
  
  stats <- stats %>%
    mutate(sh_pop     = pop_2010/first(pop_2010), 
           sh_housing = housing_units_2010/first(housing_units_2010))
  
  for (type in c("state", "county", "local")) {
    var <- paste0(type, "_event")
    stats[, paste0(var, "_sh")] = c(NA, NA, mean(pull(df_rents_panel, var), na.rm = T), 
                             mean(pull(df_rents_all, var), na.rm = T))
  }
  
  stats$mean_sfcc_psqft <- c(NA, NA, mean(pull(df_rents_all, rent_var), na.rm = T), 
                                     mean(pull(df_rents_panel, rent_var), na.rm = T))
  
  stats$non_na_zipcod <- c(NA, NA, 
                           n_distinct(df_rents_all[!is.na(pull(df_rents_all, rent_var)), "zipcode"], na.rm = T), 
                           n_distinct(df_rents_panel[!is.na(pull(df_rents_panel, rent_var)), "zipcode"], na.rm = T))
  
  desired_order <- c("pop_2010", "sh_pop", "housing_units_2010", "sh_housing", 
                     "urb_share2010", "college_share2010", "black_share2010", "hisp_share2010", 
                     "elder_share2010", "poor_share20105", "unemp_share20105", 
                     "med_hhinc20105", "renthouse_share2010", "work_county_share20105", 
                     "zip_count", "state_event_sh", "county_event_sh", "local_event_sh", 
                     "mean_sfcc_psqft", "non_na_zipcod")
  
  stats <- t(stats[, desired_order])
  colnames(stats) <- c("U.S.", "Top 100 CBSA", "Full Panel", "Est. Panel")
  
  return(stats)
}

main()
