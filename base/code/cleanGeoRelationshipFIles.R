# Preliminaries
source("../../lib/R/library.R")
load_packages(c('tidyverse', 'data.table', 'tidycensus'))

dir.create("../output/census/")

datadir <- '../../raw_data/census/'
tempdir <- "../temp/"
outputdir <- "../output/census/"

# Import custom functions
source(paste0(lib, 'load_packages.R'))
source(paste0(lib, 'fwrite_key.R'))
source(paste0(lib, 'setkey_unique.R'))


# Import libraries
load_packages(c('tidyverse', 'data.table', 'tidycensus'))

main <- function(){
   clean_2010census_gazzetter_file('Gaz_places_national.txt')
   clean_zip_place_relantionship_file('zcta_place_rel_10.txt')
   clean_zip_county_relantionship_file('zcta_county_rel_10.txt')
}


clean_2010census_gazzetter_file <- function(filename){
   places10 <- fread(paste0(datadir, filename))  
   
   places10 <- places10[USPS!='PR',]                                 
   places10[,GEOID:=str_pad(as.character(GEOID), 7, pad = "0")]
   places10[, c('state', 'place') := .((substr(GEOID, 1, 2)), (substr(GEOID, 3, 7)))]
   places10[,placetype :=word(NAME, -1)]
   places10[,NAME := gsub("\\s*\\w*$", "", NAME)]
   
   setnames(places10, old = c('USPS','NAME', 'POP10', 'ALAND'), new = c('stateabb', 'placename', 'placepop10', 'landarea'))
   varplace10 <- c('state', 'stateabb', 'place', 'placename', 'placetype', 'placepop10', 'landarea')
   places10 <- places10[,..varplace10]
   
   save_data(df = places10, key = c('state', 'place'),
             filename = paste0(outputdir, 'places10.csv'))
}


clean_zip_place_relantionship_file <- function(filename){
   zctaPlace10 <- fread(paste0(datadir,filename))

   zctaPlace10[,c('ZCTA5', 'PLACE'):= .(str_pad(as.character(ZCTA5),5 , pad = '0'), str_pad(as.character(PLACE),5, pad = '0'))]
   zctaPlace10[,STATE := str_pad(as.character(STATE), 2, pad = "0")]
   zcta_newvars <- c('zipcode', 'place', 'state', 'zippop10', 'relpop10', 'zippctpop10', 'placepctpop10', 'ziphouse10', 'zippcthouse10', 'placehouse10', 'placepcthouse10', 'zippctland')
   
   setnames(zctaPlace10, 
            old = c('ZCTA5', 'PLACE', 'STATE', 'ZPOP', 'POPPT', 'ZPOPPCT', 'PLPOPPCT', 'ZHU', 'ZHUPCT', 'PLHU', 'PLHUPCT', 'ZAREALANDPCT'), 
            new = zcta_newvars)
   zctaPlace10 <- zctaPlace10[,..zcta_newvars]
   
   save_data(df = zctaPlace10, key = c('state', 'place', 'zipcode'),
             filename = paste0(outputdir, 'zip_places10.csv'))
}


clean_zip_county_relantionship_file <- function() {
   zctaCounty10 <- fread(paste0(datadir,'zcta_county_rel_10.txt'))

   county_newvars <- c('zipcode', 'state', 'county', 'zippctpop10', 'zippcthouse10', 'zippctland')
   setnames(zctaCounty10, old = c('ZCTA5', 'STATE', 'COUNTY', 'ZPOPPCT', 'ZHUPCT', 'ZAREALANDPCT'), new = county_newvars)
   zctaCounty10 <- zctaCounty10[,..county_newvars]
   zctaCounty10[, c('county','state'):=.(str_pad(as.character(county), 3, pad ="0"), 
                                         str_pad(as.character(state), 2, pad ="0"))]
   countyNames <- fips_codes
   countyNames <- countyNames[, c('state_code', 'county_code', 'county')]
   countyNames <- setDT(countyNames)
   
   setnames(countyNames, old = c('state_code', 'county_code', 'county'), new = c('state', 'county', 'countyname'))
   zctaCounty10 <- countyNames[zctaCounty10, on = c('state', 'county')]
   USterritories <- c(60,66,69,72,78)
   zctaCounty10 <- zctaCounty10[!state %in% USterritories,]
   
   save_data(df = zctaCounty10, key = c('state', 'county', 'zipcode'),
             filename = paste0(outputdir, 'zip_county10.csv'))
}

main()
