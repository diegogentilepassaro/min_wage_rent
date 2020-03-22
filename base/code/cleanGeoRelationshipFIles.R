remove(list = ls())
source("../../lib/R/library.R")

load_packages(c('tidyverse', 'data.table', 'tidycensus'))

datadir <- '../../drive/raw_data/census/'
tempdir <- "../temp/"
outputdir <- "../output/"

main <- function(){
   
   datadir   <- '../../raw_data/census/'
   outputdir <- "../output/"
   
   clean_2010census_gazzetter(instub  = paste0(datadir, 'Gaz_places_national.txt'),
                              outstub = paste0(outputdir, 'places10.csv'),
                              key     = c('state', 'place'))
   
   clean_zip_place_relantionship(instub  = paste0(datadir, 'zcta_place_rel_10.txt'),
                                 outstub = paste0(outputdir, 'zip_places10.csv'),
                                 key      = c('state', 'place', 'zipcode'))
   
   clean_zip_county_relantionship(instub  = paste0(datadir, 'zcta_county_rel_10.txt'),
                                  outstub = paste0(outputdir, 'zip_county10.csv'),
                                  key     = c('state', 'county', 'zipcode'))
}


clean_2010census_gazzetter <- function(instub, outstub, key) {
   places10 <- fread(instub)
   
   places10 <- places10[USPS!='PR',]                                 
   places10[ , GEOID:=str_pad(as.character(GEOID), 7, pad = "0")]
   places10[ , c('state', 'place') := .((substr(GEOID, 1, 2)), (substr(GEOID, 3, 7)))]
   places10[ , placetype := word(NAME, -1)]
   places10[ , NAME := gsub("\\s*\\w*$", "", NAME)]
   
   setnames(places10, old = c('USPS','NAME', 'POP10', 'ALAND'), 
                      new = c('stateabb', 'placename', 'placepop10', 'landarea'))
   varplace10 <- c('state', 'stateabb', 'place', 'placename', 'placetype', 'placepop10', 'landarea')
   places10 <- places10[ ,..varplace10]
   
   save_data(df = places10, key = key, filename = outstub)
}


clean_zip_place_relantionship <- function(instub, outstub, key) {
   zctaPlace10 <- fread(instub)

   zctaPlace10[ ,c('ZCTA5', 'PLACE'):= .(str_pad(as.character(ZCTA5),5 , pad = "0"), 
                                        str_pad(as.character(PLACE),5,  pad = "0"))]
   zctaPlace10[ ,STATE := str_pad(as.character(STATE), 2, pad = "0")]
   
   zcta_oldvars <- c('ZCTA5', 'PLACE', 'STATE', 'ZPOP', 'POPPT', 'ZPOPPCT', 'PLPOPPCT', 'ZHU', 'ZHUPCT', 
                     'PLHU', 'PLHUPCT', 'ZAREALANDPCT')
   zcta_newvars <- c('zipcode', 'place', 'state', 'zippop10', 'relpop10', 'zippctpop10', 'placepctpop10', 
                     'ziphouse10', 'zippcthouse10', 'placehouse10', 'placepcthouse10', 'zippctland')
   
   setnames(zctaPlace10, old = zcta_oldvars, new = zcta_newvars)
   zctaPlace10 <- zctaPlace10[,..zcta_newvars]
   
   save_data(df = zctaPlace10, key = key, filename = outstub)
}


clean_zip_county_relantionship <- function(instub, outstub, key) {
   zctaCounty10 <- fread(instub)
   
   county_oldvars <- c('ZCTA5', 'STATE', 'COUNTY', 'ZPOPPCT', 'ZHUPCT', 'ZAREALANDPCT')
   county_newvars <- c('zipcode', 'state', 'county', 'zippctpop10', 'zippcthouse10', 'zippctland')
   setnames(zctaCounty10, old = county_oldvars, new = county_newvars)
   zctaCounty10 <- zctaCounty10[ ,..county_newvars]
   
   zctaCounty10[, c('county','state') := .(str_pad(as.character(county), 3, pad ="0"), 
                                           str_pad(as.character(state), 2, pad ="0"))]
   countyNames <- fips_codes
   countyNames <- countyNames[, c('state_code', 'county_code', 'county')]
   countyNames <- setDT(countyNames)
   
   setnames(countyNames, old = c('state_code', 'county_code', 'county'), new = c('state', 'county', 'countyname'))
   zctaCounty10 <- countyNames[zctaCounty10, on = c('state', 'county')]
   USterritories <- c(60,66,69,72,78)
   zctaCounty10 <- zctaCounty10[!state %in% USterritories,]
   
   save_data(df = zctaCounty10, key = key, filename = outstub)
}

main()
