#' This script cleans relationship files to crosswalk between US geogrpahies
# if (getwd()!= dirname(rstudioapi::getSourceEditorContext()$path)) setwd(dirname(rstudioapi::getSourceEditorContext()$path))


dir.create("../output/census/")

# Set dependencies
lib <- "../../lib/R/"
datadir <- '../../raw_data/census/'
tempdir <- "../temp/"
outputdir <- "../output/census/"

# Import custom functions
source(paste0(lib, 'check_packages.R'))
source(paste0(lib, 'fwrite_key.R'))
source(paste0(lib, 'setkey_unique.R'))


# Import libraries
check_packages(c('tidyverse', 'data.table', 'tidycensus'))


# clean 2010 US places Gazzetter File 
places10 <- fread(paste0(datadir, 'Gaz_places_national.txt'))    #Load file
places10<- places10[USPS!='PR',]                                 #Remove Puerto Rico Obs
places10[,GEOID:=str_pad(as.character(GEOID), 7, pad = "0")]
places10[, c('state', 'place') := .((substr(GEOID, 1, 2)), (substr(GEOID, 3, 7)))]
places10[,placetype :=word(NAME, -1)]
places10[,NAME := gsub("\\s*\\w*$", "", NAME)]
setnames(places10, old = c('USPS','NAME', 'POP10', 'ALAND'), new = c('stateabb', 'placename', 'placepop10', 'landarea'))
varplace10 <- c('state', 'stateabb', 'place', 'placename', 'placetype', 'placepop10', 'landarea')
places10<-places10[,..varplace10]

setkey_unique(places10, c('state', 'place'))
fwrite_key(places10, file = paste0(outputdir, 'places10.csv'))

# Clean Zip Code Tabulation Area (zcta) to Place Relationship File 
zctaPlace10 <- fread(paste0(datadir,'zcta_place_rel_10.txt'))
zctaPlace10[,c('ZCTA5', 'PLACE'):= .(str_pad(as.character(ZCTA5),5 , pad = '0'), str_pad(as.character(PLACE),5, pad = '0'))]
zctaPlace10[,STATE := str_pad(as.character(STATE), 2, pad = "0")]
zcta_newvars <- c('zipcode', 'place', 'state', 'zippop10', 'relpop10', 'zippctpop10', 'placepctpop10', 'ziphouse10', 'zippcthouse10', 'placehouse10', 'placepcthouse10', 'zippctland')
setnames(zctaPlace10, 
         old = c('ZCTA5', 'PLACE', 'STATE', 'ZPOP', 'POPPT', 'ZPOPPCT', 'PLPOPPCT', 'ZHU', 'ZHUPCT', 'PLHU', 'PLHUPCT', 'ZAREALANDPCT'), 
         new = zcta_newvars)
zctaPlace10 <- zctaPlace10[,..zcta_newvars]

setkey_unique(zctaPlace10, c('state', 'place', 'zipcode'))
fwrite_key(zctaPlace10, file = paste0(outputdir,'zip_places10.csv'))

# Clean Zip Code to County Relationship File 
zctaCounty10 <- fread(paste0(datadir,'zcta_county_rel_10.txt'))
county_newvars <- c('zipcode', 'state', 'county', 'zippctpop10', 'zippcthouse10', 'zippctland')
setnames(zctaCounty10, old = c('ZCTA5', 'STATE', 'COUNTY', 'ZPOPPCT', 'ZHUPCT', 'ZAREALANDPCT'), new = county_newvars)
zctaCounty10 <- zctaCounty10[,..county_newvars]
zctaCounty10[,c('county','state'):=.(str_pad(as.character(county), 3, pad ="0"),str_pad(as.character(state), 2, pad ="0"))]
countyNames <- fips_codes
countyNames <- countyNames[, c('state_code', 'county_code', 'county')]
countyNames <- setDT(countyNames)
setnames(countyNames, old = c('state_code', 'county_code', 'county'), new = c('state', 'county', 'countyname'))
zctaCounty10 <- countyNames[zctaCounty10, on = c('state', 'county')]
USterritories <- c(60,66,69,72,78)
zctaCounty10 <- zctaCounty10[!state %in% USterritories,]

setkey_unique(zctaCounty10, c('state', 'county', 'zipcode'))
fwrite_key(zctaCounty10, file = paste0(outputdir,'zip_county10.csv'))




# Clean Environment
rm(list = ls())
