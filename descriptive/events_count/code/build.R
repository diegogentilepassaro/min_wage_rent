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
  
  count_events <- function(dataset, panel) {
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
    
    text <- paste0(
      "\\newcommand{\\ZIPMWevents",
      short,
      "}{\\textnormal{",
      events,
      "}} % ZIP code MW changes in the ",
      panel,
      " sample"
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
          "MWevents",
          short,
          "}{\\textnormal{",
          events,
          "}} % ",
          gg,
          ' MW changes in the ',
          panel,
          ' sample'
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
  }
  
  for (panels in c('Unbalanced', 'Full Balanced', 'Baseline')) {
    count_events(data, panels)
  }
  
  
  # Average percent change among Zillow ZIP codes (line 143 of data_sample.tex)
  
  data[, mean_mw := fifelse(event_mw == 1, statutory_mw / shift(statutory_mw), 0)]
  
  avchange <-
    (mean(data[mean_mw > 0, mean_mw], na.rm = T) - 1) * 100
  
  text <- paste0(
    "\\newcommand{\\AvgPctChange}{\\textnormal{",
    round(avchange, 2),
    "\\%}} % Average percent change among Zillow ZIP codes"
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
