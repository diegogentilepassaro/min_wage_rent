#' Add minimum wage data to Zillow data
if (getwd()!= dirname(rstudioapi::getSourceEditorContext()$path)) setwd(dirname(rstudioapi::getSourceEditorContext()$path))

# Set dependencies
lib <- "../../lib/R/"
datadir_zillow <- '../temp/'
datadir_mw <- '../../base/output/min_wage/'
outputdir <- "../output/"
tempdir <- "../temp/"

# Import custom functions
source(paste0(lib, 'check_packages.R'))
source(paste0(lib, 'fwrite_key.R'))
source(paste0(lib, 'setkey_unique.R'))

# Import libraries
check_packages(c('tidyverse', 'data.table'))

# Load Zillow Clean Data

dfZillow <- fread(paste0(datadir_zillow, 'zillow_clean.csv'))
dfZillow[, zipcode := str_pad(as.character(zipcode), 5, pad = 0)]
head(dfZillow)

   