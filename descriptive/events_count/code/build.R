remove(list = ls())

library(data.table)

in_statutory <- '../../../drive/derived_large/min_wage'
outdir <- '../output'
out_file <- '../output/event_counts.txt'

main <- function() {
  
  files_dir <-
    list.files(
      in_statutory,
      pattern = "statutory_mw.csv",
      full.names = T
    )
  
  if (file.exists(out_file)) {
    file.remove(out_file)
  }
  
  geographies <-
    c("local", "zipcode", "county", "state") # Add local later
  
  for (gg in geographies) {
    if (gg != "zipcode") {
      data <-
        fread(files_dir[1], colClasses = c(countyfips = 'character'))
    } else {
      data <- fread(files_dir[2])
    }
    
    events <- get(paste0('count_', gg, '_events'))(data)
    
    text <- paste('Number of', gg, 'MW events:',
                  events)
    
    write.table(
      text,
      out_file,
      quote = F,
      row.names = F,
      col.names = F,
      append = T
    )
    
    remove(data)
  }
}

count_state_events <- function(data) {
  data[, state := substr(countyfips, 1, 2)]
  
  data[, state_event := fifelse(state_mw > shift(state_mw), 1, 0), by =
         countyfips]
  
  data_state <- data[,
                     .(state_event = max(state_event)),
                     by = list(month, year, state)]
  
  n <- sum(data_state$state_event, na.rm = T)
  
  return(n)
}

count_zipcode_events <- function(data) {
  data[, zipcode_event := fifelse(actual_mw > shift(actual_mw), 1, 0), by =
         zipcode]
  
  n <- sum(data$zipcode_event, na.rm = T)
  
  return(n)
}

count_county_events <- function(data) {
  # Change actual_mw to county_mw when it becomes available
  
  data[, county_event := fifelse(actual_mw > shift(actual_mw), 1, 0), by =
         countyfips]
  
  n <- sum(data$county_event, na.rm = T)
  
  return(n)
}

count_local_events <- function (data) {
  data[, local_event := fifelse(local_mw > shift(local_mw), 1, 0), by =
         countyfips]
  
  n <- sum(data$local_event, na.rm = T)
  
  return(n)
}

# Execute
main()
