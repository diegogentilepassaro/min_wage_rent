remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")

load_packages(c('tidyverse', 'data.table', 'tidycensus', 'tidyZillow'))

datadir <- "../temp/" 
outdir <- "../output/"

df <- fread(paste0(datadir, 'data_clean.csv'))

target_cols <- c('zipcode', 'date', 'county', 'stateabb', 
                 'medlistingpricepsqft_SFCC', 'medlistingprice_SFCC', 
                 'medrentprice_SFCC', 'medrentpricepsqft_SFCC', 
                 'Monthlylistings_NSA_SFCC', 'NewMonthlylistings_NSA_SFCC', 'Sale_Counts', 
                 'SalesPrevForeclosed_Share', 'pctlistings_pricedown_SFCC', 
                 'medDailylistings_NSA_SFCC', 'medpctpricereduction_SFCC', 
                 'placepop10', 'pop10_zip_county', 'houses10_zip_county', 
                 'pct_zip_houses_inplace', 'pct_zip_pop_inplace', 
                 'local_mw', 'county_mw', 'state_mw', 'actual_mw', 'Dactual_mw', 'landarea_sqkm')

df <- df[, ..target_cols]

new_names <- c('zipcode', 'date', 'county', 'stateabb', 
               'listpricepsqft_sfcc', 'listprice_sfcc', 
               'rent_sfcc', 'rentpsqft_sfcc', 
               'nlist_sfcc', 'nlist_new_sfcc', 'nsales', 
               'forecl_sales_sh', 'list_pricedown_sh_sfcc', 
               'nlist_medday_sfcc', 'medpricedown_pct_sfcc', 
               'placepop10', 'pop10_zip_county', 'houses10_zip_county', 
               'pct_zip_houses_inplace', 'pct_zip_pop_inplace', 
               'local_mw', 'county_mw', 'state_mw', 'actual_mw', 'Dactual_mw', 'landarea_sqkm')

setnames(df, old = target_cols, new = new_names)

df <- df[year(date) >=2010 & year(date)<2020, ]

save_data(df = df, 
          key = c('zipcode', 'date'), 
          filename = paste0(outdir, 'listrent_comp.dta'))


