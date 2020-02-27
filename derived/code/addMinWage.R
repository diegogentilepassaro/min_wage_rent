#' Add minimum wage data to Zillow data
# if (getwd()!= dirname(rstudioapi::getSourceEditorContext()$path)) setwd(dirname(rstudioapi::getSourceEditorContext()$path))

# Set dependencies
lib <- "../../lib/R/"
datadir_zillow <- '../temp/'
datadir <- '../../base/output/'
outputdir <- "../output/"
tempdir <- "../temp/"

# Import custom functions
source(paste0(lib, 'check_packages.R'))
source(paste0(lib, 'fwrite_key.R'))
source(paste0(lib, 'setkey_unique.R'))

# Import libraries
check_packages(c('tidyverse', 'data.table', 'matrixStats'))

# Load Zillow Clean Data
dfZillow <- fread(paste0(datadir_zillow, 'zillow_clean.csv'))
dfZillow[, zipcode := str_pad(as.character(zipcode), 5, pad = 0)] #format zipcode
dfZillow[,date := as.Date(paste0(date, "_01"), "%Y_%m_%d")]       #format date
dfZillow[,county:=NULL]                                           #eliminate county vairable(redundant as it's going to be added later)


# Load Min Wage - State Level
dfStatemw <- fread(paste0(datadir, 'min_wage/VZ_state_monthly.csv'))
setnames(dfStatemw, old = c('statefips', 'monthly_date'), new = c('state', 'date'))
dfStatemw[,date := str_replace_all(date, "m", "_")][,date:= as.Date(paste0(date, "_01"), "%Y_%m_%d")]
setnames(dfStatemw, old = c('min_mw', 'mean_mw', 'max_mw'), new = c('min_state_mw', 'mean_state_mw', 'max_state_mw'))

# Load Min Wage - Local Level 
dfLocalmw <- fread(paste0(datadir, 'min_wage/VZ_substate_monthly.csv'))
setnames(dfLocalmw, old = c('statefips', 'monthly_date'), new = c('state', 'date'))
dfLocalmw[,date := str_replace_all(date, "m", "_")][,date:= as.Date(paste0(date, "_01"), "%Y_%m_%d")]
dfLocalmw[,iscounty:=str_extract_all(locality, " County")][,iscounty:= ifelse(iscounty==" County", 1, 0)]    #Identify county-level vs city-level min wages

dfCountymw <- dfLocalmw[iscounty==1,][,iscounty:=NULL]    #extract county level min wage
setnames(dfCountymw, old = c('locality', 'min_mw', 'mean_mw', 'max_mw', 'abovestate'), new = c('countyname', 'min_county_mw', 'mean_county_mw', 'max_county_mw', 'countyabovestate'))   #format county level min wage variables

dfLocalmw <- dfLocalmw[iscounty==0,][,iscounty:=NULL]    #extract city level min wage 
setnames(dfLocalmw, old = c('locality', 'min_mw', 'mean_mw', 'max_mw', 'abovestate'), new = c('placename', 'min_local_mw', 'mean_local_mw', 'max_local_mw', 'localabovestate'))              #format city level min wage


# Load zcta to place relationship file 
place10 <- fread(paste0(datadir, 'census/places10.csv'))
place10 <- place10[placetype=="city",] #Keep only cities (as local min wages are applied in cities and counties only)
zip_places10 <- fread(paste0(datadir,'census/zip_places10.csv'))
setorder(zip_places10, zipcode)
zip_places10 <- zip_places10[zippcthouse10>=50,] # Keep only zip code place matches where at least 50 percent of houses are in zipcode
zip_places10 <- place10[zip_places10, on = c('state', 'place')]
zip_places10[, zipcode := str_pad(as.character(zipcode), 5, pad = 0)]


# Load zcta to county relationship file 
zip_county10 <- fread(paste0(datadir,'census/zip_county10.csv'))
setorder(zip_county10, zipcode)
zip_county10 <- zip_county10[zippcthouse10>=50,] # Keep only zip code county matches where at least 50 percent of houses are in zipcode
zip_county10[, ind := max(zippctpop10, na.rm = T), by = 'zipcode'][, ind:= ifelse(ind==zippctpop10, 1, 0)]
zip_county10 <- zip_county10[ind==1,]
zip_county10 <- zip_county10[, ind:=NULL]
zip_county10[, zipcode := str_pad(as.character(zipcode), 5, pad = 0)]


# Select variables to merge with Zillow Data (some are redundant)
zip_county10<- zip_county10[, c('state', 'county', 'countyname', 'zipcode', 'zippctpop10', 'zippcthouse10', 'zippctland')]
zip_places10 <- zip_places10[, c('zipcode','place', 'placename', 'placetype', 'placepop10')]

# Assemble Final Dataset 
DF <- dfZillow
DF <- zip_county10[dfZillow, on = 'zipcode']                                           # Add county names
DF <- zip_places10[DF, on = 'zipcode']                                                 # Add Place names
DF <- dfStatemw[DF, on = c('state', 'stateabb', 'date')]                               # Add State Level Minimum wage
DF <- dfCountymw[DF, on = c('state', 'statename', 'stateabb', 'countyname', 'date')]   # Add county level minimum wage
DF <- dfLocalmw[DF, on = c('state', 'statename', 'stateabb', 'placename', 'date')]     # Add city level minimum wage

colorder1 <- c('date', 'zipcode', 'place', 'placename', 'city', 'msa', 'county', 'countyname', 'state', 'stateabb', 'statename')
colorder2 <- setdiff(colorder1, names(DF))
setcolorder(DF, c(colorder1,colorder2))

# Create actual mininum wage for each zipcode (compare federal, state, county and place minimum wages and take the max)
DF[,min_actual_mw:= rowMaxs(as.matrix(DF[,c('min_fed_mw', 'min_state_mw', 'min_county_mw', 'min_local_mw')]), na.rm = T)][,min_actual_mw:= ifelse(min_actual_mw==-Inf, NA, min_actual_mw)]
DF[,mean_actual_mw:= rowMaxs(as.matrix(DF[,c('mean_fed_mw', 'mean_state_mw', 'mean_county_mw', 'mean_local_mw')]), na.rm = T)][,mean_actual_mw:= ifelse(mean_actual_mw==-Inf, NA, mean_actual_mw)]
DF[,max_actual_mw:= rowMaxs(as.matrix(DF[,c('max_fed_mw', 'max_state_mw', 'max_county_mw', 'max_local_mw')]), na.rm = T)][,max_actual_mw:= ifelse(max_actual_mw==-Inf, NA, max_actual_mw)]

# Create event dummy (and change in minimum wage)
setorderv(DF, cols = c('zipcode', 'date'))
DF[,Dmin_actual_mw := min_actual_mw - shift(min_actual_mw), by = 'zipcode'][,min_event := ifelse(Dmin_actual_mw>0,1,0)]
DF[,Dmean_actual_mw := mean_actual_mw - shift(mean_actual_mw), by = 'zipcode'][,mean_event := ifelse(Dmean_actual_mw>0,1,0)]
DF[,Dmax_actual_mw := max_actual_mw - shift(max_actual_mw), by = 'zipcode'][,max_event := ifelse(Dmax_actual_mw>0,1,0)]

# Set key and Save 
setkey_unique(DF, cols = c('zipcode', 'date'))
fwrite_key(DF, file = paste0(outputdir, 'data_clean.csv'))

# Clean Environment
rm(list = ls())
