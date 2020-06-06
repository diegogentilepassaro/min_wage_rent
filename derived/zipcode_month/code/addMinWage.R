remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")

load_packages(c('tidyverse', 'data.table', 'matrixStats'))

main <- function(){
   datadir   <- '../../../base/zillow_min_wage/output/'
   tempdir   <- "../temp/"
   log_file  <- "../output/data_file_manifest.log"
   
   data <- load_data(infile_zillow  = paste0(tempdir, 'zillow_clean.csv'), 
                     infile_statemw = paste0(datadir, 'VZ_state_monthly.csv'), 
                     infile_localmw = paste0(datadir, 'VZ_substate_monthly.csv'),
                     infile_place   = paste0(datadir, 'places10.csv'),
                     infile_county  = paste0(datadir,'zip_county10.csv'),
                     infile_zipplace = paste0(datadir,'zip_places10.csv'))
   
   data <- assemble_data(data)

   data <- create_minwage_eventvars(data)

   save_data(df = data, key = c('zipcode', 'date'),
             filename = paste0(tempdir, 'data_clean.csv'), nolog = TRUE)
}

load_data <- function(infile_zillow, infile_statemw, infile_localmw,
                      infile_place, infile_county, infile_zipplace) {


   dfZillow <- fread(infile_zillow)
   
   dfZillow[,zipcode := str_pad(as.character(zipcode), 5, pad = 0)]
   dfZillow[,date := as.Date(paste0(date, "_01"), "%Y_%m_%d")]


   dfStatemw <- fread(infile_statemw)
   setnames(dfStatemw, old = c('monthly_date', 'mw'), new = c('date', 'state_mw'))
   dfStatemw[,date := str_replace_all(date, "m", "_")][,
              date := as.Date(paste0(date, "_01"), "%Y_%m_%d")]
   dfStatemw[,statefips := str_pad(as.character(statefips), 2, pad = 0)]

   dfLocalmw <- fread(infile_localmw)
   setnames(dfLocalmw, old = c('monthly_date'), new = c('date'))
   dfLocalmw[,date := str_replace_all(date, "m", "_")][,
              date := as.Date(paste0(date, "_01"), "%Y_%m_%d")]
   dfLocalmw[,statefips := str_pad(as.character(statefips), 2, pad = 0)]
   dfLocalmw[,iscounty := str_extract_all(locality, " County")][,
              iscounty := ifelse(iscounty == " County", 1, 0)]


   mw_vars <- names(dfLocalmw)
   mw_vars <- mw_vars[grepl("mw", mw_vars)]
   
   county_mw_vars <- paste0("county_", mw_vars)
   local_mw_vars <- paste0("local_", mw_vars)
   

   dfCountymw <- dfLocalmw[iscounty == 1,][,iscounty := NULL]
   setnames(dfCountymw, old = c('locality', mw_vars), 
                        new = c('county', county_mw_vars))
   
   dfLocalmw <- dfLocalmw[iscounty == 0,][,iscounty := NULL]
   setnames(dfLocalmw, old = c('locality', mw_vars),
                       new = c('placename', local_mw_vars))
   

   usps_zip_to_zcta <- load_xwalk_zip_zcta('../../../raw/crosswalk/zip_to_zcta_2019.xlsx')
   

   place10 <- fread(infile_place)
   setnames(place10, old = c("state"), new = c("statefips"))
   place10[,statefips := str_pad(as.character(statefips), 2, pad = 0)]
   place10[,place_code := str_pad(as.character(place_code), 5, pad = 0)]
   # place10 <- place10[placetype=="city",]

   zip_places10 <- fread(infile_zipplace, 
                         colClasses = c("place_code" = "character", "zcta" = "character",
                                        "statefips"  = "character"))
   setorder(zip_places10, zcta)

   zip_places10 <- place10[zip_places10, on = c('statefips', 'place_code')]
   zip_places10 <- zip_places10[pct_zip_houses_inplace >= 50,]
   zip_places10 <- left_join(zip_places10, usps_zip_to_zcta, by = c('zcta'))
   
   
   zip_county10 <- fread(infile_county, 
                        colClasses = c("zcta" = "character", "statefips" = "character",
                                       "county_code" = "character", "countyfips" = "character"))
   setorder(zip_county10, zcta)

   zip_county10 <- zip_county10[pct_zip_houses_incounty >= 50,]
   zip_county10[,ind := max(pct_zip_pop_incounty, na.rm = T),by = 'zcta'][,
                 ind := ifelse(ind == pct_zip_pop_incounty, 1, 0)]

   zip_county10 <- zip_county10[ind == 1,]
   zip_county10 <- zip_county10[,ind := NULL]
   zip_county10 <- left_join(zip_county10, usps_zip_to_zcta, by = c('zcta'))
   

   return(list('df_zillow'    = dfZillow,     'df_state_mw' = dfStatemw,
               'df_county_mw' = dfCountymw,   'df_local_mw' = dfLocalmw,
               'zip_county'   = zip_county10, 'zip_place'   = zip_places10))
}

load_xwalk_zip_zcta <- function(path) {
   df <- readxl::read_excel(path)
   setnames(df, old = c('ZIP_CODE', 'ZCTA'), new = c('zipcode', 'zcta'))
   df <- df[,c('zipcode', 'zcta')]

   return(df)
}

assemble_data <- function(data) {

   DF <- data[['df_zillow']]

   DF <- left_join(DF, data[['df_state_mw']], by=c('stateabb', 'date'))
   DF <- left_join(DF, data[['zip_county']], by=c('statefips', 'stateabb', 'zipcode'))
   DF <- subset(DF, select = -c(statename, county.x, county_code))
   setnames(DF, old = c("county.y"), new = "county")

   DF <- left_join(DF, data[['zip_place']], by=c('statefips', 'stateabb', 'zipcode'))
   DF <- subset(DF, select = -c(zcta.x))
   setnames(DF, old = c("zcta.y"), new = "zcta")

   DF <- left_join(DF, data[['df_county_mw']], by=c('statefips', 'stateabb', 'county', 'date'))
   DF <- subset(DF, select = -c(statename))

   DF <- left_join(DF, data[['df_local_mw']], by=c('statefips', 'stateabb', 'placename', 'date'))
   DF <- subset(DF, select = -c(statename))
   
   colorder1 <- c('date', 'zipcode', 'zcta', 'place_code', 'placename', 'placetype', 
                  'city', 'msa', 'countyfips', 'county', 'statefips', 'stateabb')
   colorder2 <- setdiff(colorder1, names(DF))

   setcolorder(DF, c(colorder1,colorder2))

   return(as.data.table(DF))
}

create_minwage_eventvars <- function(x){
   
   mw_vars <- names(x)
   mw_vars <- mw_vars[grepl("mw", mw_vars)]
   mw_vars <- mw_vars[!grepl("abovestate", mw_vars)]
   
   mw_vars_regular <- mw_vars[!grepl("smallbusiness", mw_vars)]
   
   mw_vars_smallb <- c(mw_vars[grepl('smallbusiness', mw_vars)], 
                       'fed_mw', 'state_mw') 

   x[,actual_mw := rowMaxs(as.matrix(x[,..mw_vars_regular]), na.rm = T)][,
      actual_mw:= ifelse(actual_mw == -Inf, NA, actual_mw)]

   x[,actual_mw_smallbusiness := rowMaxs(as.matrix(x[,..mw_vars_smallb]), na.rm = T)][,
      actual_mw_smallbusiness := ifelse(actual_mw_smallbusiness == -Inf, NA, actual_mw_smallbusiness)]
   
   setorderv(x, cols = c('zipcode', 'date'))
   x[,Dactual_mw := actual_mw - shift(actual_mw), by = 'zipcode'][,
      mw_event := ifelse(Dactual_mw > 0 , 1, 0)]
   x[,Dactual_mw_smallbusiness := actual_mw_smallbusiness - shift(actual_mw_smallbusiness), by = 'zipcode'][,
      mw_event_smallbusiness := ifelse(Dactual_mw_smallbusiness > 0 , 1, 0)]

   return(x)
}

main()
