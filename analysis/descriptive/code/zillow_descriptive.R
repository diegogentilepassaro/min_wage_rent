remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")

load_packages(c('tidyverse', 'data.table', 'tidycensus', 'matrixStats', 'knitr', 'kableExtra', 'ggplot2', 'png', 'grid'))

theme_set(theme_minimal())

main <- function() {
   datadir <- "../../../drive/derived_large/output/"
   outdir <- "../output/"
   tempdir <- "../temp/"
   
   df <- fread(paste0(datadir, "data_clean.csv"))
   
   df <- prepare_data(df)

   descriptive_table(df, outdir)

   zillow_plots(df, outdir)
}


prepare_data <- function(x) {
   x[,date := as.Date(date, "%Y-%m-%d")]
}


descriptive_table <- function(d, outstub) {
   
   d <- setDT(d)
   
   geovars <- c('zipcode', 'date', 'city', 'msa', 'county', 'statename', 'stateabb', 'i.statename', 'place', 'placename', 'countyname', 'state', 'year', 'placetype', 'placepop10', 'zippctpop10', 'zippcthouse10', 'zippctland')
   

   minwage_vars <- names(d) %>%
      str_subset(pattern = "mw")
   
   
   zillow_varlist <- setdiff(colnames(d), 
                             c(geovars, minwage_vars))
   
   
   d[, year := as.numeric(substr(date, 1,4))]
   
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
      
      tot_zip <- length(unique(d[!is.na(get(x)),]$zipcode))
      totNA_zip <- length(unique(d$zipcode)) - tot_zip
      
      results <- c('totNA' = totNA_zip, 'tot_zip' = tot_zip)
      return(results)
   })
   zillow_missingZip <- t(zillow_missingZip)
   
   
   
   zillow_sumstats <- sapply(zillow_varlist, function(x) {
      
      
      if (x %in% post2010_varlist) d <- d[year>=2010,]
      
      sel_vars <- c('zipcode', 'mw_event', x)
      
      data <- d[,..sel_vars]
      
      data[, isNA := is.na(get(x))][
         isNA==0, ]
      
      N <- data[, .N]
      
      data_len <- data[,.N, by = zipcode]
      
      summstats <- function(x) list(mean = mean(x, na.rm = T), sd = sd(x, na.rm = T), median = median(x, na.rm = T), min = min(x, na.rm = T), max = max(x, na.rm = T))
      
      len_subtable <- data_len[,unlist(lapply(.SD, summstats)), .SDcols = c('N')]
      
      event_per_zip <- data[,.(N.event = sum(mw_event, na.rm = T)), by = zipcode][,.(N.event = mean(N.event, na.rm = T))]
      
      event_per_zip <- event_per_zip$N.event
      
      summary_var <- data[,unlist(lapply(.SD, summstats)), .SDcols = x]
      
      names(summary_var) <- c('mean', 'SD', 'median', 'min', 'max')
      
      
      results <- c( len_subtable,
                    'EventPerZip' = event_per_zip,
                    'N' = N,
                    summary_var)
      
      
      return(results)
   })
   zillow_sumstats <- t(zillow_sumstats)
   
   
   options('scipen' = 999, 'digits' = 4)
   final_table <- setDT(data.frame('ZillowSeries' = row.names(zillow_missingZip),
                                   zillow_missingZip,
                                   zillow_sumstats))
   
   save_data(final_table,
             key = 'ZillowSeries',
             filename = paste0(outstub, 'zillow_descriptive.csv'))
}


zillow_plots <- function(data, outstub) {
   geovars <- c('zipcode', 'date', 'city', 'msa', 'county', 'statename', 'stateabb', 'i.statename', 'place', 'placename', 'countyname', 'state', 'year', 'placetype', 'placepop10', 'zippctpop10', 'zippcthouse10', 'zippctland')
   
   
   minwage_vars <- names(data) %>%
      str_subset(pattern = "mw")
   
   
   zillow_varlist <- setdiff(colnames(data), 
                             c(geovars, minwage_vars))
   
   plots <- lapply(zillow_varlist, function(x) {
      cols <- c('date', x)
      d <- data[,..cols]
      
      d <- d[is.na(get(x))==0,]
      
      sdmean <- function(y) {
         sdm <- sd(y, na.rm = T) / sqrt(length(y))
         return(sdm)
      }
      
      d <- d[, .('mean' = mean(get(x), na.rm = T), 'sdm' = sdmean(get(x))), by = 'date']
      d[, c('CIlow', 'CIup'):= .((mean - 1.96*sdm), (mean + 1.96*sdm))]
      
      
      d[,date := as.Date(date, format = "%Y-%m-%d")]
      brks <- c('2010-06-01', '2011-06-01', '2012-06-01', '2013-06-01', '2014-06-01', '2015-06-01', '2016-06-01', '2017-06-01', '2018-06-01', '2019-06-01')
      brks <- as.Date(brks, format = "%Y-%m-%d")
      lbls <- lubridate::year(brks)
      
      plot <- ggplot(d, aes(x = date, group = 1)) +
         geom_line(aes(y = mean)) +
         geom_ribbon(aes(ymin = CIlow, ymax = CIup), fill = "gray80", alpha = 0.8) +
         labs(title = x,
              caption = "Source: Zillow.com") + 
         scale_x_date(labels = lbls, breaks = brks)
      print(plot)
      return(plot)
   })
   names(plots) <- zillow_varlist
   
   pdf(paste0(outstub,'zillow_plots.pdf'))
   lapply(plots,function(x){
      img <- x
      grid.draw(img)
   })
   dev.off()
}


main()
