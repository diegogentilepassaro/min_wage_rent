# Preliminaries
source("../../lib/R/library.R")
load_packages(c('tidyverse', 'data.table', 'tidycensus', 'matrixStats', 'knitr', 'kableExtra', 'ggplot2', 'png', 'grid'))
theme_set(theme_minimal())

main <- function() {
   datadir <- "../../derived/output/"
   outdir <- "../output/"
   tempdir <- "../temp/"
   
   df <- fread(paste0(datadir, "data_clean.csv"))
   # return(df)
   # df <- sample_f(df, 0.01)
   descriptive_table(df, outdir)
   zillow_plots(df, outdir)
   
   
}


prepare_data <- function(x) {
   x[,date := as.Date(date, "%Y_%m_%d")]
}


descriptive_table <- function(d, outstub) {
   
   d <- setDT(d)
   
   geovars <- c('zipcode', 'date', 'city', 'msa', 'county', 'statename', 'stateabb', 'i.statename', 'place', 'placename', 'countyname', 'state', 'year')
   
   minwage_vars <- c('min_local_mw', 'mean_local_mw', 'max_local_mw', 'localabovestate', 'min_county_mw', 'mean_county_mw', 'max_county_mw', 'countyabovestate', 'min_fed_mw', 'mean_fed_mw', 'max_fed_mw', 'min_state_mw', 'mean_state_mw', 'max_state_mw', 'min_actual_mw', 'mean_actual_mw', 'max_actual_mw', 'Dmin_actual_mw', 'Dmean_actual_mw', 'Dmax_actual_mw', 'min_event', 'mean_event', 'max_event', 'placetype', 'placepop10', 'zippctpop10', 'zippcthouse10', 'zippctland')
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
      
      sel_vars <- c('zipcode', 'max_event', x)
      
      data <- d[,..sel_vars]
      
      data[, isNA := is.na(get(x))][
         isNA==0, ]
      
      N <- data[, .N]
      
      data_len <- data[,.N, by = zipcode]
      
      summstats <- function(x) list(mean = mean(x), sd = sd(x), median = median(x), min = min(x), max = max(x))
      
      len_subtable <- data_len[,unlist(lapply(.SD, summstats)), .SDcols = c('N')]
      
      event_per_zip <- data[,.(N.event = sum(max_event, na.rm = T)), by = zipcode][,.(N.event = mean(N.event, na.rm = T))]
      
      event_per_zip <- event_per_zip$N.event
      
      min <- min(data[,get(x)], na.rm = T)
      
      mean <- mean(data[,get(x)], na.rm = T)
      
      SD <- sd(data[,get(x)], na.rm = T)
      
      max <- max(data[,get(x)], na.rm = T)
      
      
      results <- c( len_subtable,
                   'EventPerZip' = event_per_zip,
                   'N' = N,
                   'mean' = mean,
                   'SD' = SD,
                   'min' = min,
                   'max' = max)
      
      
      return(results)
   })
   zillow_sumstats <- t(zillow_sumstats)
   
   
   options('scipen' = 999, 'digits' = 4)
   final_table <- setDT(data.frame('ZillowSeries' = row.names(zillow_missingZip),
                                   zillow_missingZip,
                                   zillow_sumstats))
   
   # save_data(final_table, 
   #           key = 'ZillowSeries', 
   #           filename = paste0(outstub, 'zillow_descriptive.csv'))
   fwrite(final_table, file = paste0(outstub, 'zillow_descriptive.csv'))
}


zillow_plots <- function(data, outstub) {
   geovars <- c('zipcode', 'date', 'city', 'msa', 'county', 'statename', 'stateabb')
   
   minwage_vars <- c('min_local_mw', 'mean_local_mw', 'max_local_mw', 'localabovestate', 'min_county_mw', 'mean_county_mw', 'max_county_mw', 'countyabovestate', 'min_fed_mw', 'mean_fed_mw', 'max_fed_mw', 'min_state_mw', 'mean_state_mw', 'max_state_mw', 'min_actual_mw', 'mean_actual_mw', 'max_actual_mw', 'Dmin_actual_mw', 'Dmean_actual_mw', 'Dmax_actual_mw', 'min_event', 'mean_event', 'max_event', 'placetype', 'placepop10', 'zippctpop10', 'zippcthouse10', 'zippctland', 'i.statename', 'place', 'placename', 'countyname', 'state', 'year')
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
      brks <- d$date[seq(1,length(d$date), 12)]
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
      grid.newpage()
      grid.draw(img)
   })
   dev.off()
}


main()