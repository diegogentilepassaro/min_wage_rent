remove(list = ls())
source("../../lib/R/library.R")
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
   dfZillow[,county:=NULL]
   

   dfStatemw <- fread(infile_statemw)
   setnames(dfStatemw, old = c('statefips', 'monthly_date'), new = c('state', 'date'))
   dfStatemw[,date := str_replace_all(date, "m", "_")][,date:= as.Date(paste0(date, "_01"), "%Y_%m_%d")]
   setnames(dfStatemw, old = c('min_mw', 'mean_mw', 'max_mw'), new = c('min_state_mw', 'mean_state_mw', 'max_state_mw'))
   
   dfLocalmw <- fread(infile_localmw)
   setnames(dfLocalmw, old = c('statefips', 'monthly_date'), new = c('state', 'date'))
   dfLocalmw[,date := str_replace_all(date, "m", "_")][,date:= as.Date(paste0(date, "_01"), "%Y_%m_%d")]
   dfLocalmw[,iscounty:=str_extract_all(locality, " County")][,iscounty:= ifelse(iscounty==" County", 1, 0)]
   
   dfCountymw <- dfLocalmw[iscounty==1,][,iscounty:=NULL]
   setnames(dfCountymw, old = c('locality', 'min_mw', 'mean_mw', 'max_mw', 'abovestate'), 
                        new = c('countyname', 'min_county_mw', 'mean_county_mw', 'max_county_mw', 'countyabovestate'))
   
   dfLocalmw <- dfLocalmw[iscounty==0,][,iscounty:=NULL]
   setnames(dfLocalmw, old = c('locality', 'min_mw', 'mean_mw', 'max_mw', 'abovestate'), 
                       new = c('placename', 'min_local_mw', 'mean_local_mw', 'max_local_mw', 'localabovestate'))              
   
   
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
   min_mwage_vars<-c('min_fed_mw', 'min_state_mw', 'min_county_mw', 'min_local_mw')
   mean_mwage_vars<-c('mean_fed_mw', 'mean_state_mw', 'mean_county_mw', 'mean_local_mw')
   max_mwage_vars<-c('max_fed_mw', 'max_state_mw', 'max_county_mw', 'max_local_mw')
   
   x[ , min_actual_mw := 
        rowMaxs(as.matrix(x[,..min_mwage_vars]), na.rm = T)][ , min_actual_mw:= ifelse(min_actual_mw == -Inf, 
                                                                                        NA, min_actual_mw)]
   x[ , mean_actual_mw := 
        rowMaxs(as.matrix(x[,..mean_mwage_vars]), na.rm = T)][ ,mean_actual_mw:= ifelse(mean_actual_mw == -Inf, 
                                                                                        NA, mean_actual_mw)]
   x[ , max_actual_mw := 
        rowMaxs(as.matrix(x[,..max_mwage_vars]), na.rm = T)][ ,max_actual_mw:= ifelse(max_actual_mw == -Inf,
                                                                                      NA, max_actual_mw)]
   
   setorderv(x, cols = c('zipcode', 'date'))
   x[,Dmin_actual_mw := min_actual_mw - shift(min_actual_mw), by = 'zipcode'][,min_event := ifelse(Dmin_actual_mw > 0 , 1, 0)]
   x[,Dmean_actual_mw := mean_actual_mw - shift(mean_actual_mw), by = 'zipcode'][,mean_event := ifelse(Dmean_actual_mw > 0 , 1, 0)]
   x[,Dmax_actual_mw := max_actual_mw - shift(max_actual_mw), by = 'zipcode'][,max_event := ifelse(Dmax_actual_mw > 0 , 1, 0)]
    
   return(x)
}

main()
