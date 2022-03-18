count_events <- function(data, panel, geographies) {
  
  if (panel == "Unbalanced") {
    data_sample <- data
    short <- 'Unbal'
  } else if (panel == "Full Balanced") {
    data_sample <- data[fullbal_sample == 1]
    short <- 'Full'
  } else if (panel == "Baseline") {
    data_sample <- data[baseline_sample == 1]
    short <- 'Base'
  }
  
  events <- sum(data_sample$event_mw, na.rm = T)
  
  text <- write_command(paste0("ZIPMWevents",short),events)
  
  output_events <- text
  
  for (i in 1:3) {
    gg <- geographies[i]
    
    data_agg <- data_sample[binding_mw_max == i + 1,
                            .(event_geo = max(event_mw)),
                            by = c(gg, 'year_month')]
    
    events <- sum(data_agg$event_geo, na.rm = T)
    
    name <- paste0(gg,"MWevents",short)
    
    text <- write_command(name,events)
    
    output_events <- paste0(output_events,text)
    
  }
  return(output_events)
}


count_local <- function(data, panel) {
  if (panel == "Unbalanced") {
    data_sample <- data
    short <- 'Unbal'
  } else if (panel == "Full Balanced") {
    data_sample <- data[fullbal_sample == 1]
    short <- 'Full'
  } else if (panel == "Baseline") {
    data_sample <- data[baseline_sample == 1]
    short <- 'Base'
  }
  data_agg <- data_sample[binding_mw_max %in% c(3, 4),
                          .(event_local = max(event_mw)),
                          by = c("county", 'year_month')]
  
  events <- sum(data_agg$event_local, na.rm = T)
  
  text <- write_command(paste0("CityCountyMWevents",short), events)
  
  return(text)
}
