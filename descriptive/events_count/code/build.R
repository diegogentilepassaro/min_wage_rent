remove(list = ls())

library(data.table)

main <- function() {
  in_sample <- '../../../drive/derived_large/estimation_samples'
  out_file <- '../output/events_count.tex'
  
  if (file.exists(out_file)) file.remove(out_file)
  
  data <- fread(
    file.path(in_sample, 'zipcode_months.csv'),
    colClasses = list(
      character = c('zipcode', 'countyfips', 'statefips', 'place_code')
    ),
    select = c(
      'zipcode',
      'countyfips',
      'statefips',
      'place_code',
      'statutory_mw',
      'binding_mw',
      'binding_mw_max',
      'year_month',
      'baseline_sample',
      'fullbal_sample'
    )
  )
  
  geographies <-
    c("state", "county", "local")
  
  old_names <- c('statefips', 'countyfips', 'place_code')
  
  setnames(data, old_names, geographies)
  
  data[, event_mw := fifelse(statutory_mw > shift(statutory_mw), 1, 0), 
       by = 'zipcode']
  
  events <- sum(data$event_mw, na.rm = T)
  
  text <- paste0(
    "\\newcommand{\\ZIPMWeventsUnbal}{\\textnormal{",
    events,
    "}} \n% ZIP code MW changes in the Unbalanced sample"
  )
  
  write.table(
    text,
    out_file,
    quote = F,
    row.names = F,
    col.names = F,
    append = T
  )
  
  for (i in 1:3) {
    gg <- geographies[i]
    
    data_agg <-
      data[binding_mw_max == i + 1,
           .(event_geo = max(event_mw)),
           by = c(gg, 'year_month')]
    
    events <- sum(data_agg$event_geo, na.rm = T)
    
    text <- paste0(
      "\\newcommand{\\",
      gg,
      "MWeventsUnbal}{\\textnormal{",
      events,
      "}} \n% ",
      gg,
      ' MW changes in the Unbalanced sample'
    )
    
    write.table(
      text,
      out_file,
      quote = F,
      row.names = F,
      col.names = F,
      append = T
    )
  }
  
  # Baseline sample
  
  data_sample <- data[baseline_sample == 1]
  
  events <- sum(data_sample$event_mw, na.rm = T)
  
  text <- paste0(
    "\\newcommand{\\ZIPMWeventsBase}{\\textnormal{",
    events,
    "}} \n% ZIP code MW changes in the Baseline sample"
  )
  
  write.table(
    text,
    out_file,
    quote = F,
    row.names = F,
    col.names = F,
    append = T
  )
  
  for (i in 1:3) {
    gg <- geographies[i]
    
    data_agg <-
      data_sample[binding_mw_max == i + 1,
                  .(event_geo = max(event_mw)),
                  by = c(gg, 'year_month')]
    
    events <- sum(data_agg$event_geo, na.rm = T)
    
    text <-
      paste0(
        "\\newcommand{\\",
        gg,
        "MWeventsBase}{\\textnormal{",
        events,
        "}} \n% ",
        gg,
        ' MW changes in the Baseline sample'
      )
    
    write.table(
      text,
      out_file,
      quote = F,
      row.names = F,
      col.names = F,
      append = T
    )
  }
  
  # Full balanced sample
  
  data_sample <- data[fullbal_sample == 1]
  
  events <- sum(data_sample$event_mw, na.rm = T)
  
  text <- paste0(
    "\\newcommand{\\ZIPMWeventsFull}{\\textnormal{",
    events,
    "}} \n% ZIP code MW changes in the Full Balanced sample"
  )
  
  write.table(
    text,
    out_file,
    quote = F,
    row.names = F,
    col.names = F,
    append = T
  )
  
  for (i in 1:3) {
    gg <- geographies[i]
    
    data_agg <-
      data_sample[binding_mw_max == i + 1,
                  .(event_geo = max(event_mw)),
                  by = c(gg, 'year_month')]
    
    events <- sum(data_agg$event_geo, na.rm = T)
    
    text <-
      paste0(
        "\\newcommand{\\",
        gg,
        "MWeventsFull}{\\textnormal{",
        events,
        "}} \n% ",
        gg,
        ' MW changes in the Full Balanced sample'
      )
    
    write.table(
      text,
      out_file,
      quote = F,
      row.names = F,
      col.names = F,
      append = T
    )
  }
  
  # Average percent change among Zillow ZIP codes (line 143 of data_sample.tex)
  
  data[, mean_mw := fifelse(event_mw == 1, statutory_mw / shift(statutory_mw), 0)]
  
  avchange <-
    (mean(data[mean_mw > 0, mean_mw], na.rm = T) - 1) * 100
  
  text <- paste0(
    "\\newcommand{\\AvgPctChange}{\\textnormal{",
    round(avchange, 2),
    "\\%}}\n% Average percent change among Zillow ZIP codes"
  )
  
  write.table(
    text,
    out_file,
    quote = F,
    row.names = F,
    col.names = F,
    append = T
  )
  
}

# Execute
main()
