remove(list = ls())

library(data.table)

main <- function() {
  in_sample <- '../../../drive/derived_large/estimation_samples'
  out_file <- '../output/events_count.txt'
  
  if (file.exists(out_file))  file.remove(out_file)
  
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
      'year_month'
    )
  )
  
  geographies <-
    c("state", "county", "local")
  
  old_names <- c('statefips', 'countyfips', 'place_code')
  
  setnames(data, old_names, geographies)
  
  data[, event_mw := fifelse(statutory_mw > shift(statutory_mw), 1, 0), by =
         'zipcode']
  
  events <- sum(data$event_mw, na.rm = T)
  
  text <- paste('Number of MW events at the ZIP code level:',
                events)
  
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
      data[binding_mw == i + 1, .(event_mw = max(event_mw)), by = c(gg, 'year_month')]
    
    events <- sum(data_agg$event_mw, na.rm = T)
    
    text <- paste('Number of MW events at the', gg, 'level:',
                  events)
    
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

# Execute
main()
