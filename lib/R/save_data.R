library(foreign)

save_data <- function(df, filename, key, logfile = NULL) {
  
  df <- check_key(df, key)
  
  
  if (!is.null(logfile)) {
    # Write log file in given folder
  } else {
    # Write log file in df folder. Check if log file exists and update it
  }
}

check_key <- function(df, key) {
  
  if (!(key %in% colnames(df))) {
    
    stop("KeyError: Key variables are not in df.")
    
  } else if (!isid(df, key)) {
    
    stop("KeyError: Key variables do not uniquely identify observations.")
    
  } else {

    reordered_colnames <- c(key, colnames(df[!x %in% grep(paste0(key, collapse = "|"), x, value = T)]))
    
    df <- df[order(key), ]
    df <- df[reordered_colnames]
    
    return(df)
  }
}