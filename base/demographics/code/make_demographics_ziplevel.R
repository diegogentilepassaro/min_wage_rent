remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")

load_packages(c('tidyverse', 'data.table', 'tidycensus', 'bit64', 'readxl'))

main <- function() {
   
   data_version <- "0043"
   
   datadir <- paste0("../../../drive/raw_data/census/tract/nhgis", data_version, "_csv/")
   xwalkdir <- "../../../raw/crosswalk/" 
   outdir  <- "../output/"
   tempdir <- "../temp"
         
   table_list <- list.files(datadir, 
                            pattern = "*.csv")
   
   table_list <- str_remove_all(table_list, paste0("nhgis", data_version, "_"))
   
   table_clean <- lapply(table_list, format_tables, datadir = datadir, data_version = data_version)
   
   table_final <- Reduce(function(x,y) merge(x,y, all = T, by = c('tract_fips', 'county_fips')), table_clean)
   
   xwalk <- read_excel(paste0(xwalkdir, "TRACT_ZIP_122012.xlsx"), 
                       col_names = c('tract_fips', 'zipcode', 'res_ratio', 'bus_ratio', 'oth_ratio', 'tot_ratio'),
                       col_types = c('numeric', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric'))
   xwalk <- setDT(xwalk)
   xwalk[, c('res_ratio', 'bus_ratio', 'oth_ratio'):= NULL]
   xwalk <- xwalk[!is.na(zipcode), ]

   
   table_final <- table_final[xwalk, on = 'tract_fips']
   
   
   start_geo <- 'tract_fips'
   target_geo <- 'zipcode'
   wgt <- 'tot_ratio'
   demovars <- setdiff(colnames(table_final), c(start_geo, target_geo, wgt, 'county_fips'))
   
   table_final <- table_final[, lapply(.SD, weighted.mean, w = tot_ratio, na.rm = T), by = target_geo, .SDcols = demovars]
   
   
   save_data(table_final,
             filename = paste0(outdir, 'zip_demo.csv'),
             key = c('zipcode'))
}




format_tables <- function(x, datadir, data_version) {
   data <- fread(paste0(datadir, "nhgis", data_version, "_", x))

   
   make_geo <-  function(y) {
      if (class(y)[1] != "data.table") y <- setDT(y)

      y[, c('tract_fips', 'county_fips') := list(
         as.numeric(paste0(
            str_pad(STATEA, 2, pad = "0"),
            str_pad(COUNTYA, 3, pad = "0"),
            str_pad(TRACTA, 6, pad = "0"))),
         as.numeric(paste0(str_pad(STATEA, 2, pad = "0"),
                           str_pad(COUNTYA, 3, pad = "0"))))]

      return(y)
   }
   data <- make_geo(data)

   if (x == "ds172_2010_tract.csv") {
      
      data[ , 'pop2010' := H7V001]
      
      data[ , 'urb_share2010' := (H7W002 / H7W001)]
      
      data[, c('white_share2010', 
               'black_share2010', 
               'hisp_share2010', 
               'asian_share2010', 
               'natam_share2010') := 
              list((H7Z003 / H7Z001), 
                   (H7Z004 / H7Z001), 
                   (H7Z010 / H7Z001), 
                   (H7Z006 / H7Z001), 
                   (H7Z007 / H7Z001))]
      
      data[, c('child_share2010',      #0-14
               'teen_share2010',       #15-21
               'youngadult_share2010', #22-34
               'adult_share2010',      #35-64
               'elder_share2010') :=   #65-
              list((H76003 + H76004 + H76005 + H76027 + H76028 + H76029) / H76001, 
                   (H76006 + H76007 + H76008 + H76009 + H76030 + H76031 + H76032 + H76033) / H76001, 
                   (H76010 + H76011 + H76012 + H76034 + H76035 + H76036) / H76001, 
                   (H76013 + H76014 + H76015 + H76016 + H76017 + H76018 + H76019 + H76037 + H76038 + H76039 + H76040 + H76041 + H76042 + H76043) / H76001,
                   (H76020 + H76021 + H76022 + H76023 + H76024 + H76025 + H76044 + H76045 + H76046 + H76047 + H76048 + H76049) / H76001)]
      
      
      data[, 'housing_units2010':= IFC001]
      
      target_vars <- c('tract_fips', 'county_fips', 
                       'pop2010', 
                       'urb_share2010', 
                       'white_share2010', 'black_share2010', 'hisp_share2010', 'asian_share2010', 'natam_share2010', 
                       'child_share2010', 'teen_share2010', 'youngadult_share2010', 'adult_share2010', 'elder_share2010', 
                       'housing_units2010')
      
      
   }
   
   else if (x == 'ds173_2010_tract.csv') {
      
      data[, c('hh_couple_share2010',            #share of couples (married or partners) out of household population
               'hh_couple_child_share2010') :=   #share of couples with children under 18 out of couple household population
              list((IC6002 + IC6013) / IC6001, 
                   (IC6004 + IC6009 + IC6015 + IC6020 + IC6025 + IC6030) / (IC6002 + IC6013))]
    
      target_vars <- c('tract_fips', 'county_fips', 
                       'hh_couple_share2010', 'hh_couple_child_share2010')
      
      data <- data[ ,..target_vars]
   }
   
   else if (x == 'ds181_2010_tract.csv') {
      data[, c('renthouse_share2010') :=  #share of housing units that are renter-occupied 
              list(LHT004 / LHT001)]
      
      target_vars <- c('tract_fips', 'county_fips', 
                       'renthouse_share2010')
      
   }
   
   else if (x == 'ds191_20125_2012_tract.csv') {
      
      data[, 'work_county_share20105' := QS6E003 / QS6E001]
      
      data[, c('worktravel_10_share20105',      #travel time to work less than 10 minutes (share of workers not at home)
               'worktravel_10_60_share20105',   #travel time to work between 10 and 60 minutes
               'worktravel_60_share20105') :=   #travel time to work equal or above 60 minutes
              list((QTHE002 + QTHE003) / QTHE001, 
                   (QTHE004 + QTHE005 + QTHE006 + QTHE007 + QTHE008 + QTHE009 + QTHE010 + QTHE011) / QTHE001, 
                   (QTHE012 + QTHE013) / QTHE001)]
      
      data[, 'college_share20105' := (QUSE021 + QUSE022 + QUSE023+ QUSE024 + QUSE025) / QUSE001]
      
      data[, 'poor_share20105' := (QUVE002 + QUVE003) / QUVE001]
      
      data[, c('lo_hhinc_share20105',       #share of households with income lower than 45k
               'hi_hhinc_share20105') :=   #share of households with income higher or equal than 100k
              list((QU0E002 + QU0E003 + QU0E004 + QU0E005 + QU0E006 + QU0E007 + QU0E008 + QU0E009) / QU0E001, 
                   (QU0E014 + QU0E015 + QU0E016 + QU0E017) / QU0E001)]
      
      data[, 'med_hhinc20105' := QU1E001]
      
      data[, 'unemp_share20105' := QXSE005 / QXSE002]
      
      data[, 'employee_share20105' := (QX5E004 + QX5E014 + QX5E006 + QX5E016 + QX5E007 + QX5E008 + QX5E009 + QX5E017 + QX5E018 + QX5E019) / QX5E001]
      
      target_vars <- c('tract_fips', 'county_fips', 
                       'work_county_share20105', 
                       'worktravel_10_share20105', 'worktravel_10_60_share20105', 'worktravel_60_share20105', 
                       'college_share20105', 
                       'poor_share20105', 
                       'lo_hhinc_share20105', 'hi_hhinc_share20105',
                       'med_hhinc20105',
                       'unemp_share20105', 
                       'employee_share20105')
      
      
      
   }
   
   else if (x == 'ds192_20125_2012_tract.csv') {
      
      data[, c('med_earn_healthsup_20105',       #median earnings (USD 2012) for healthcare support occup.
               'med_earn_protectserv_20105',     #median earnings (USD 2012) for protective services (police, etc)
               'med_earn_foodserv_20105',        #median earnings (USD 2012) for food prod and serving occ.
               'med_earn_cleaning_20105',        #median earnings (USD 2012) for cleaning and maintenance occup. 
               'med_earn_perscare_20105',        #median earnings (USD 2012) for personal care and service occup.
               'med_earn_prodtransp_20105') :=   #median earnings (USD 2012) for production, transport and moving occup.
              list(REPE019, 
                   REPE020, 
                   REPE023, 
                   REPE024, 
                   REPE025, 
                   REPE033)]
      
      target_vars <- c('tract_fips', 'county_fips', 
                       'med_earn_healthsup_20105', 'med_earn_protectserv_20105', 'med_earn_foodserv_20105', 'med_earn_cleaning_20105', 'med_earn_perscare_20105', 'med_earn_prodtransp_20105')
      
      
   }
   data <- data[, ..target_vars]
   

   return(data)
}

main()