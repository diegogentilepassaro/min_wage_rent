remove(list = ls())

library(data.table)

in_samples <- '../../../drive/derived_large/estimation_samples'
outdir <- '../output'
out_file <- '../output/event_counts.txt'

main <- function() {
  files_dir <-
    list.files(in_samples, pattern = ".csv", full.names = T)[-2] # Ignore all_zipcode_months (too big)
  file.remove(out_file)
  
  for (dd in files_dir) {
    file_name <- stringr::str_remove(dd, '.*/')
    
    data <- fread(dd)
    
    data[, mw_event := fifelse(actual_mw != shift(actual_mw), 1, 0), by =
           county_num]
    
    n <- sum(data$mw_event == 1, na.rm = T)
    
    text <- paste0('Number of MW changes in ', file_name, ": ",
                   n)
    
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

# Execute
main()
