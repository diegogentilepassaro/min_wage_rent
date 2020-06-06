remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")

load_packages(c('tidyverse', 'data.table', 'tidycensus', 'bit64'))

main <- function(){
   
   datadir   <- '../../../drive/raw_data/census/'
   outputdir <- "../output/"
   
   clean_2010census_gazzetter(indir = datadir, outdir = outputdir,
                              key   = c('state', 'place_code'))
   
   clean_zip_place_relationship(indir = datadir, outdir = outputdir,
                                key   = c('place_code', 'zcta'))
   
   clean_zip_county_relationship(indir = datadir, outdir = outputdir,
                                 key   = c('countyfips', 'zcta'))
}

clean_2010census_gazzetter <- function(indir, outdir, key) {
   places10 <- fread(paste0(indir, 'Gaz_places_national.txt'))
   
   places10$ALAND <- as.numeric(places10$ALAND*1e-6)
   
   places10 <- places10[USPS!='PR',]                                 
   places10[ , GEOID := str_pad(as.character(GEOID), 7, pad = "0")]
   places10[ , c('state', 'place_code') := .((substr(GEOID, 1, 2)), (substr(GEOID, 3, 7)))]
   places10[ , placetype := word(NAME, -1)]
   places10[ , NAME := gsub("\\s*\\w*$", "", NAME)]
   
   setnames(places10, old = c('USPS','NAME', 'POP10', 'ALAND'), 
            new = c('stateabb', 'placename', 'placepop10', 'landarea_sqkm'))

   varplace10 <- c('state', 'stateabb', 'place_code', 'placename', 'placetype', 'placepop10', 
                   'landarea_sqkm')
   places10 <- places10[ ,..varplace10]
   
   save_data(df = places10, key = key, 
             filename = paste0(outdir, 'places10.csv'),
             logfile  = paste0(outdir, "geo_data_manifest.log"))
}

clean_zip_place_relationship <- function(indir, outdir, key) {
   zctaPlace10 <- fread(paste0(indir, 'zcta_place_rel_10.txt'), 
                        colClasses = c("ZCTA5"="character", "PLACE"="character", 
                                       "STATE"="character"))
   
   zcta_oldvars <- c('ZCTA5', 'PLACE', 'STATE', 
                     'POPPT', 'HUPT', 'ZPOPPCT',
                     'ZHUPCT')
   zcta_newvars <- c('zcta', 'place_code', 'statefips', 
                     'pop10_zip_place', 'houses10_zip_place', 'pct_zip_pop_inplace',
                     'pct_zip_houses_inplace')
   
   setnames(zctaPlace10, old = zcta_oldvars, new = zcta_newvars)
   zctaPlace10 <- zctaPlace10[ ,..zcta_newvars]
   
   USterritories <- c(60,66,69,72,78)
   zctaPlace10 <- zctaPlace10[!statefips %in% USterritories,]
   
   save_data(df = zctaPlace10, key = key, 
             filename = paste0(outdir, 'zip_places10.csv'),
             logfile  = paste0(outdir, "geo_data_manifest.log"))
}

clean_zip_county_relationship <- function(indir, outdir, key) {
   zctaCounty10 <- fread(paste0(indir, 'zcta_county_rel_10.txt'), 
                         colClasses = c(rep("character",4), rep("numeric", 20)))
   
   county_oldvars <- c('ZCTA5', 'STATE', 'COUNTY')
   county_newvars <- c('zcta', 'state_code', 'county_code')
   setnames(zctaCounty10, old = county_oldvars, new = county_newvars)

   countyNames <- fips_codes
   countyNames$countyfips <- paste0(as.character(countyNames$state_code),
                                    as.character(countyNames$county_code))
   
   countyNames <- countyNames[, c('state_code', 'state', 'county_code', 'county', 'countyfips')]
   countyNames <- setDT(countyNames)
   
   zctaCounty10 <- left_join(zctaCounty10, countyNames, by = c('state_code', 'county_code'))

   USterritories <- c(60,66,69,72,78)
   zctaCounty10 <- zctaCounty10[!zctaCounty10$state_code %in% USterritories,]
   
   oldnames <- c('state_code', 'state', 'POPPT', 
                 'HUPT', 'ZPOPPCT', 'ZHUPCT')
   newnames <- c('statefips', 'stateabb', 'pop10_zip_county', 
                 'houses10_zip_county', 'pct_zip_pop_incounty','pct_zip_houses_incounty')
   setnames(zctaCounty10, old = oldnames, new = newnames)
   
   zctaCounty10 <- zctaCounty10[ ,c("zcta", "statefips", "stateabb", "countyfips", "county_code", 
                                    "county", 'pop10_zip_county', "houses10_zip_county",
                                    "pct_zip_pop_incounty", "pct_zip_houses_incounty")]

   save_data(df = zctaCounty10, key = key, 
             filename = paste0(outdir, 'zip_county10.csv'),
             logfile  = paste0(outdir, "geo_data_manifest.log"))
}

main()
