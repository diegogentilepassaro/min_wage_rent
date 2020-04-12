remove(list = ls())
source("../../lib/R/load_packages.R")
source("../../lib/R/save_data.R")

load_packages(c('tidyverse', 'data.table', 'matrixStats'))


main <- function(){
   datadir   <- '../../base/output/'
   outputdir <- "../../drive/derived_large/output/"
   tempdir   <- "../temp/"
   log_file  <- "../output/data_file_manifest.log"
   
   data <- load_data(infile_zillow = paste0(tempdir, 'zillow_clean.csv'), 
                     infile_statemw = paste0(datadir, 'VZ_state_monthly.csv'), 
                     infile_localmw = paste0(datadir, 'VZ_substate_monthly.csv'), 
                     infile_place = paste0(datadir, 'places10.csv'), 
                     infile_county = paste0(datadir,'zip_county10.csv'), 
                     infile_zipplace = paste0(datadir,'zip_places10.csv'))
   
   data <- assemble_data(data)

   data <- create_minwage_eventvars(data)

   save_data(df = data, key = c('zipcode', 'date'),
             filename = paste0(outputdir, 'data_clean.csv'), logfile = log_file)
}

load_data <- function(infile_zillow, infile_statemw, infile_localmw, infile_place, infile_county, infile_zipplace){
   dfZillow <- fread(infile_zillow)
   
   dfZillow[, zipcode := str_pad(as.character(zipcode), 5, pad = 0)]
   dfZillow[,date := as.Date(paste0(date, "_01"), "%Y_%m_%d")]
   dfZillow[,c('county', 'statename'):=NULL]
   

   dfStatemw <- fread(infile_statemw)
   setnames(dfStatemw, old = c('statefips', 'monthly_date', 'mw'), new = c('state', 'date', 'state_mw'))
   dfStatemw[,date := str_replace_all(date, "m", "_")][,date:= as.Date(paste0(date, "_01"), "%Y_%m_%d")]

   dfLocalmw <- fread(infile_localmw)
   setnames(dfLocalmw, old = c('statefips', 'monthly_date'), new = c('state', 'date'))
   dfLocalmw[,date := str_replace_all(date, "m", "_")][,date:= as.Date(paste0(date, "_01"), "%Y_%m_%d")]
   dfLocalmw[,iscounty:=str_extract_all(locality, " County")][,iscounty:= ifelse(iscounty==" County", 1, 0)]

   mw_vars <- names(dfLocalmw)
   mw_vars <- mw_vars[grepl("mw", mw_vars)]
   
   county_mw_vars <- paste0("county_", mw_vars)
   local_mw_vars <- paste0("local_", mw_vars)
   
   dfCountymw <- dfLocalmw[iscounty==1,][,iscounty:=NULL]
   setnames(dfCountymw, old = c('locality', mw_vars), 
                        new = c('countyname', county_mw_vars))
   
   dfLocalmw <- dfLocalmw[iscounty==0,][,iscounty:=NULL]
   setnames(dfLocalmw, old = c('locality', mw_vars), 
                       new = c('placename', local_mw_vars))
   
   place10 <- fread(infile_place)
   place10 <- place10[placetype=="city",]
   zip_places10 <- fread(infile_zipplace)
   setorder(zip_places10, zipcode)
   zip_places10 <- zip_places10[zippcthouse10>=50,]
   zip_places10 <- place10[zip_places10, on = c('state', 'place')]
   zip_places10[, zipcode := str_pad(as.character(zipcode), 5, pad = 0)]
   
   zip_county10 <- fread(infile_county)
   setorder(zip_county10, zipcode)
   zip_county10 <- zip_county10[zippcthouse10>=50,]
   zip_county10[, ind := max(zippctpop10, na.rm = T), by = 'zipcode'][, ind:= ifelse(ind==zippctpop10, 1, 0)]
   zip_county10 <- zip_county10[ind==1,]
   zip_county10 <- zip_county10[, ind:=NULL]
   zip_county10[, zipcode := str_pad(as.character(zipcode), 5, pad = 0)]
   
   zip_county10<- zip_county10[, c('state', 'county', 'countyname', 'zipcode', 'zippctpop10', 'zippcthouse10', 'zippctland')]
   zip_places10 <- zip_places10[, c('zipcode','place', 'placename', 'placetype', 'placepop10')]

   
   return(list('df_zillow'    = dfZillow,     'df_state_mw' = dfStatemw,
               'df_county_mw' = dfCountymw,   'df_local_mw' = dfLocalmw,
               'zip_county'   = zip_county10, 'zip_place'   = zip_places10))
}

assemble_data <- function(l) {
   DF <- l[['df_zillow']]
   DF <- l[['zip_county']][l[['df_zillow']], on = 'zipcode']
   DF <- l[['zip_place']][DF, on = 'zipcode']                                                 
   DF <- l[['df_state_mw']][DF, on = c('state', 'stateabb', 'date')]                               
   DF <- l[['df_county_mw']][DF, on = c('state', 'statename', 'stateabb', 'countyname', 'date')]   
   DF <- l[['df_local_mw']][DF, on = c('state', 'statename', 'stateabb', 'placename', 'date')]     
   
   colorder1 <- c('date', 'zipcode', 'place', 'placename', 'city', 'msa', 'county', 
                  'countyname', 'state', 'stateabb', 'statename')
   colorder2 <- setdiff(colorder1, names(DF))
   setcolorder(DF, c(colorder1,colorder2))
   return(DF)
}

create_minwage_eventvars <- function(x){
   
   mw_vars <- names(x)
   mw_vars <- mw_vars[grepl("mw", mw_vars)]
   mw_vars <- mw_vars[!grepl("abovestate", mw_vars)]
   
   mw_vars_regular <- mw_vars[!grepl("smallbusiness", mw_vars)]
   
   mw_vars_smallb <- c(mw_vars[grepl('smallbusiness', mw_vars)], 
                       'fed_mw', 'state_mw') 

   
   x[ , actual_mw := 
        rowMaxs(as.matrix(x[,..mw_vars_regular]), na.rm = T)][ , actual_mw:= ifelse(actual_mw == -Inf, 
                                                                                        NA, actual_mw)]
   x[ , actual_mw_smallbusiness := 
        rowMaxs(as.matrix(x[,..mw_vars_smallb]), na.rm = T)][ ,actual_mw_smallbusiness:= ifelse(actual_mw_smallbusiness == -Inf, 
                                                                                        NA, actual_mw_smallbusiness)]
   
   setorderv(x, cols = c('zipcode', 'date'))
   x[,Dactual_mw := actual_mw - shift(actual_mw), by = 'zipcode'][,mw_event := ifelse(Dactual_mw > 0 , 1, 0)]
   x[,Dactual_mw_smallbusiness := actual_mw_smallbusiness - shift(actual_mw_smallbusiness), by = 'zipcode'][,mw_event_smallbusiness := ifelse(Dactual_mw_smallbusiness > 0 , 1, 0)]

   return(x)
}

main()