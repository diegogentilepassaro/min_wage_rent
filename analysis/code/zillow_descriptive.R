# Preliminaries
source("../../lib/R/library.R")
load_packages(c('tidyverse', 'data.table', 'tidycensus'))

main <- function() {
   datadir <- "../../derived/temp/"
   outdir <- "../output/"
   tempdir <- "../temp/"
   
   df <- fread(paste0(datadir, "zillow_clean.csv"))
   
   clean_df <- prepare_data(df)
   return(clean_df)
}


prepare_data <- function(x) {
   x[,date := as.Date(paste0(date, "_01"), "%Y_%m_%d")]
}


output<- main()


descriptive_table <- function(d) {
   options(scipen = 999)
   geovars <- c('zipcode', 'date', 'city', 'msa', 'county', 'statename', 'stateabb')
   zillow_varlist <- setdiff(colnames(d), geovars)
   
   d[, year := as.numeric(format(date, '%Y'))]
   
   pre2010_varlist <- sapply(zillow_varlist, function(v) {
      first_year <- d[
         !is.na(get(v)), 
         ]
      
      first_year <- min(first_year$year, na.rm = T)
    
      return(first_year)
   })
   
   pre2010_varlist<- names(pre2010_varlist[pre2010_varlist<2010])
   post2010_varlist <- setdiff(zillow_varlist, pre2010_varlist)
   
   
   zillow_missingZip <- sapply(zillow_varlist, function(x) {
      
      if (x %in% post2010_varlist) d <- d[year>=2010,]
      
      totNA_zip <- d[,.(n_units = sum(is.na(get(x)))), by = zipcode][n_units==0, .N]
      tot_zip <- d[,.(n_units = sum(is.na(get(x)))), by = zipcode][n_units>0, .N]

      results <- c('totNA' = totNA_zip, 'tot_zip' = tot_zip)
      return(results)
   })
   zillow_missingZip <- t(zillow_missingZip)

   zillow_sumstats <- sapply(zillow_varlist, function(x) {
      
      if (x %in% post2010_varlist) d <- d[year>=2010,]

      sel_vars <- c('zipcode', x)

      data <- d[,..sel_vars]

      data[, n_units := sum(is.na(get(x))), by = zipcode]

      data <- data[n_units >0, ]

      N <- data[, .N]

      min <- min(data[,get(x)], na.rm = T)

      mean <- mean(data[,get(x)], na.rm = T)

      SD <- sd(data[,get(x)], na.rm = T)

      max <- max(data[,get(x)], na.rm = T)

      results <- c('N' = N,
                   'mean' = mean,
                   'SD' = SD,
                   'min' = min,
                   'max' = max)


      return(results)
   })
   zillow_sumstats <- t(zillow_sumstats)

   final_table <- setDT(data.frame('ZillowSeries' = row.names(zillow_missingZip),
                                   zillow_missingZip,
                                   zillow_sumstats))

   return(final_table)
}


z <- descriptive_table(output)


length(unique(output[!is.na(medrentprice_1BR),]$zipcode))

output[,.(n_units = sum(is.na(medrentprice_1BR))), by = zipcode][n_units>0, .N]

z <- output[,c('date', 'zipcode', 'medrentprice_1BR')]
