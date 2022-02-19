remove(list = ls())

library(data.table)

in_samples <- '../../../drive/derived_large/estimation_samples'
outdir <- '../output'
out_file <- '../output/event_counts.txt'

main <- function() {
  files_dir <-
    list.files(
      '../../../drive/derived_large/min_wage',
      pattern = "statutory_mw.csv",
      full.names = T
    )
  if (file.exists(out_file)) file.remove(out_file)
  
  states <- c("zipcode", "county", "state") # Add local later
  
  for (ss in states) {
    if (ss != "zipcode") data <- fread(files_dir[1])
    else data <- fread(files_dir[2])
    
    events <- get(paste0('count_', ss, '_events'))(data)
    
    text <- paste('Number of', ss, 'MW events:',
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
  data[,
       countyfips := fifelse(nchar(countyfips) == 4,
                             paste0(0, countyfips),
                             as.character(countyfips))][,
                                                        state := substr(countyfips, 1, 2)]
  
  data_state <- data[,
                     .(state_mw = unique(state_mw)),
                     by = list(month, year, state)]
  
  data_state[, state_event := fifelse(state_mw > shift(state_mw), 1, 0), by =
               state]
  
  n <- sum(data_state$state_event, na.rm = T)
  
  return(n)
  remove(data_state)
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
  
}

# Execute
main()
