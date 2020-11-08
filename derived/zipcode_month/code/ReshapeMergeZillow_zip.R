remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")

load_packages(c('tidyverse', 'data.table', 'tidycensus'))

main <- function() {
   datadir <- '../../../base/zillow_min_wage/output/'
   tempdir <- '../temp/'
   
   filelist <- reshape_zillow_zip_level(infolder = datadir)

   merge_zillow(l = filelist, outstub = paste0(tempdir, 'zillow_clean.csv'),
                key = c('zipcode', 'date'))
}

reshape_zillow_zip_level <- function(infolder) {
   
   filenames <- list.files(infolder)
   filenames <- filenames[str_detect(filenames, "Zip_*")]
   filenames <- filenames[!str_detect(filenames, "_Summary.csv")]
   
   value_names <- str_replace_all(filenames, "Zip_", "")
   value_names <- target_varname(value_names)
   value_names <- str_replace(value_names, ".csv", "")


   id_fullvars <- c("zipcode", "city", "county", "msa", "stateabb")

   zillow_data <- mapply(reshape_zillow_file,
      filename = filenames, valname = value_names,
      MoreArgs = list(infolder, id_fullvars), SIMPLIFY = F)
   
   return(zillow_data)
}

reshape_zillow_file <- function(filename, valname, infolder, id_fullvars) {
   
   data <- fread(paste0(infolder, filename), stringsAsFactors = F)

   idvars <- colnames(data)
   idvars <- idvars[!str_detect(idvars, "[0-9]")]

   data <- data.table::melt(data,
                            id.vars = idvars,
                            variable.name = 'date',
                            value.name = valname)

   missing_id_vars <- setdiff(id_fullvars, idvars)
   data[, (missing_id_vars):= ""]
            
   return(data)
}

merge_zillow <- function(l, outstub, key) {

   geovars <- c('zipcode', 'city', 'msa', 'county', 'stateabb')

   geovar_df <- lapply(l, function(x) {
      state_name <- x[,..geovars]
      state_name <- unique(state_name)
   })
   geovar_df <- rbindlist(geovar_df, use.names = T)
   geovar_df <- unique(geovar_df)
   geovar_df <- as.data.frame(geovar_df)

   geovar_df[geovar_df == ""] <- NA

   geovar_df <- setDT(geovar_df)[,lapply(.SD, function(y) y[!is.na(y)]),
                                  by = c('zipcode', 'city', 'msa', 'county')]
   
   geovar_df <- geovar_df[,city := str_replace_all(city, "^Town of ", "")][,
                           city := str_replace_all(city, " Township$", "")]
   
   geovar_df <- geovar_df[,lapply(.SD, function(y) y[!is.na(y)]),
                           by = c('zipcode', 'city', 'msa', 'county')]
   geovar_df <- unique(geovar_df)
   
   geovar_df <- geovar_df[,totNA := rowSums(is.na(geovar_df))]
   
   geovar_df <- geovar_df[,minNA := min(totNA), by = zipcode][
      totNA == minNA,]
   
   setkey(geovar_df, 'zipcode')
   geovar_df <- geovar_df[J(unique(zipcode)), mult = "first"]
   
   geovar_df[,c('totNA', 'minNA') := NULL]
         
   
   exclude_geo <- setdiff(c(geovars, 'date'), key)

   l <- lapply(l, function(y) y[, (exclude_geo) := NULL])

   file_combined <-  Reduce(function(x,y,m = mvars){merge(x, y, all = T, by = key)}, l)
   file_combined <- setDT(geovar_df)[file_combined, on = 'zipcode']

   data.table::setorder(file_combined, zipcode, date)

   file_combined[,date := str_replace_all(date, "-", "_")]
   
   save_data(file_combined, filename = outstub, 
             key = key, nolog = TRUE)
}

target_varname <- function(x) {

   x <- str_replace_all(x, "AllHomes", "SFCC")
   x <- str_replace_all(x, "SingleFamilyResidence", "SF")
   x <- str_replace_all(x, "Condominium", "C")
   x <- str_replace_all(x, "Condominum", "C")
   x <- str_replace_all(x, "1Bedroom", "1BR")
   x <- str_replace_all(x, "1bedroom", "1BR")
   x <- str_replace_all(x, "2Bedroom", "2BR")
   x <- str_replace_all(x, "2bedroom", "2BR")
   x <- str_replace_all(x, "3Bedroom", "3BR")
   x <- str_replace_all(x, "3bedroom", "3BR")
   x <- str_replace_all(x, "4Bedroom", "4BR")
   x <- str_replace_all(x, "4bedroom", "4BR")
   x <- str_replace_all(x, "5BedroomOrMore", "5BR")
   x <- str_replace_all(x, "CondoCoop", "CC")
   x <- str_replace_all(x, "Sfr", "SF")
   x <- str_replace_all(x, "DuplexTriplex", "MFdxtx")
   x <- str_replace_all(x, "Mfr5PLus", "MF5")
   x <- str_replace_all(x, "BottomTier", "low_tier")
   x <- str_replace_all(x, "MiddleTier", "mid_tier")
   x <- str_replace_all(x, "TopTier", "top_tier")
   x <- str_replace_all(x, "MultiFamilyResidenceRental", "MF")
   x <- str_replace_all(x, "SingleFamilyResidenceRental", "SF")
   x <- str_replace_all(x, "SingleFamilyResidenceRental", "SF")
   x <- str_replace_all(x, "PlusMultifamily", "MF")

   x <- str_replace_all(x, "ListingsWithPriceReductions", "listings_pricedown")
   x <- str_replace_all(x, "Zhvi", "zhvi")
   x <- str_replace_all(x, "Zri", "zri")
      
   x <- str_replace_all(x, "Listing", "listing")
   x <- str_replace_all(x, "Median", "med")
   x <- str_replace_all(x, "Price", "price")
   x <- str_replace_all(x, "PerSqft", "psqft")
   x <- str_replace_all(x, "PctOf", "pct")
   x <- str_replace_all(x, "Reductions", "reductions")
   x <- str_replace_all(x, "Reduction", "reduction")
   x <- str_replace_all(x, "Rental", "rent")
   x <- str_replace_all(x, "Homes", "homes")
   x <- str_replace_all(x, "Homes", "homes")
   x <- str_replace_all(x, "With", "")
   
   return(x)
}


main()
