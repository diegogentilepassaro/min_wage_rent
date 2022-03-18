remove(list = ls())
library(data.table)
library(stringr)

source('../../../lib/R/write_command.R')

main <- function() {
  in_sample     <- '../../../drive/derived_large/estimation_samples'
  in_estimates  <- '../../../analysis/fd_baseline/output'
  outstub       <- '../output'
  out_estimates <- '../output/estimates.tex'
  out_events    <- '../output/events_count.tex'
  
  varchar <- c("zipcode", "countyfips", "statefips", "place_code", "year_month")
  varnum <-  c("statutory_mw", "binding_mw", "binding_mw_max", 
               "mw_res", "mw_wkp_tot_17", "mw_wkp_age_under29_17", 
               "mw_wkp_earn_under1250_17","baseline_sample", "fullbal_sample")

  dt <- fread(file.path(in_sample, 'zipcode_months.csv'),
                colClasses = list(character = varchar,
                                  numeric   = varnum))
  
  # Correlation matrix  
  vars <- c("mw_wkp_tot_17", "mw_wkp_age_under29_17", "mw_wkp_earn_under1250_17")  
  corrmatrix <- cor(dt[, ..vars])
  
  stargazer::stargazer(corrmatrix, summary = F, digits = 4,
                       type = "text",
                       out  = file.path(outstub, "corrmatrix.txt"))
  
  
  # MW summary statistics  
  geographies <- c("state", "county", "local")
  
  old_names <- c("statefips", "countyfips", "place_code")
  
  setnames(dt, old_names, geographies)
  
  dt[, event_mw := fifelse(statutory_mw > shift(statutory_mw), 1, 0),
       by = "zipcode"]
  
  output_summary <- ""
  
  for (panels in c("Unbalanced", "Fully Balanced", "Baseline")) {
    output_summary <- paste0(output_summary, count_events(dt, panels, geographies))
    output_summary <- paste0(output_summary, count_local(dt, panels))
  }
  
  # Average percent change among Zillow ZIP codes (line 143 of data_sample.tex)  
  dt[, mean_mw := fifelse(event_mw == 1, statutory_mw / shift(statutory_mw), 0)]  
  avchange <- (mean(dt[mean_mw > 0, mean_mw], na.rm = T) - 1) * 100
  
  text <- write_command("AvgPctChange", round(avchange, 2))
  
  output_summary <- paste0(output_summary, text)
  
  write.table(output_summary, 
              file.path(outstub, "events_count.tex"),
              quote = F, row.names = F, col.names = F)
}


count_events <- function(data, panel, geographies) {
  
  sample_data <- filter_data(data, panel)
  short_name  <- sample_data$short_name
  dt_sample   <- sample_data$dt_sample

  events <- sum(dt_sample$event_mw, na.rm = T)
  
  text <- write_command(paste0("ZIPMWevents", short_name), events)
  
  output_events <- text
  
  for (i in 1:3) {
    gg <- geographies[i]
    
    data_agg <- dt_sample[binding_mw_max == i + 1,
                          .(event_geo = max(event_mw)),
                          by = c(gg, "year_month")]
    
    events <- sum(data_agg$event_geo, na.rm = T)
    
    name <- paste0(toupper_first_letter(gg), "MWevents", short_name)
    
    text <- write_command(name,events)
    
    output_events <- paste0(output_events, text)    
  }

  return(output_events)
}


count_local <- function(data, panel) {

  sample_data <- filter_data(data, panel)
  short_name  <- sample_data$short_name
  dt_sample   <- sample_data$dt_sample

  data_agg <- dt_sample[binding_mw_max %in% c(3, 4),
                        .(event_local = max(event_mw)),
                        by = c("county", "year_month")]
  
  events <- sum(data_agg$event_local, na.rm = T)
    
  return(write_command(paste0("CityCountyMWevents", short_name), events))
}

filter_data <- function(data, panel) {

  if (panel == "Unbalanced") {
    dt_sample  <- data
    short_name <- "Unbal"
  } else if (panel == "Fully Balanced") {
    dt_sample  <- data[fullbal_sample == 1]
    short_name <- "Fullbal"
  } else if (panel == "Baseline") {
    dt_sample  <- data[baseline_sample == 1]
    short_name <- "Base"
  }

  return(list("dt_sample" = dt_sample, "short_name" = short_name))
}

toupper_first_letter <- function(text) {
  return(paste0(toupper(substr(text, 1, 1)), substr(text, 2, nchar(text))))
}

# Execute
main()
