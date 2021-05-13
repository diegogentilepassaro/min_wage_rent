library('stargazer')
library('digest')
library('dplyr')
library('haven')
library('data.table')

save_data <- function(df, key, filename, logfile = NULL, nolog = FALSE) {
  
  filetype <- substr(filename, nchar(filename) - 2, nchar(filename))
  dir      <- dirname(filename)
  
  df <- check_key(df, key)
  
  if (filetype %in% c("csv", "CSV")) {
    
    fwrite(df, file = filename)
    print(paste0("File '", filename, "' saved successfully."))
    
  } else if (filetype == "dta") {
    
    write_dta(df, filename)
    print(paste0("File '", filename, "' saved successfully."))
    
  } else if (filetype == "RDS") {
    
    saveRDS(df, filename)
    print(paste0("File '", filename, "' saved successfully."))
    
  } else {
    stop("Incorrect format. Only .csv, .dta, and .RDS are allowed.")
  }
  
  if (!nolog) {
    if (!is.null(logfile)) {
      generate_log_file(df, key, filename, logfile)
    } else {
      generate_log_file(df, key, filename, sprintf("%s/data_file_manifest.log", dir))
    }
  }
}

colMean  <- function(data) sapply(data, mean, na.rm = TRUE)
colSD  <- function(data) sapply(data, sd, na.rm = TRUE)
colMin <- function(data) sapply(data, min, na.rm = TRUE)
colMax <- function(data) sapply(data, max, na.rm = TRUE)

check_key <- function(df, key) {
  
  df <- as.data.frame(df)
  
  nunique <- nrow(unique(df[key]))
  
  if (!any(key %in% colnames(df))) {
    
    stop("KeyError: Key variables are not in df.")
    
  } else if (nrow(df) != nunique) {
    
    stop("KeyError: Key variables do not uniquely identify observations.")
    
  } else {
    
    reordered_colnames <- c(key, colnames(df[!colnames(df) %in% grep(paste0(key, collapse = "|"), 
                                                                     key, value = T)]))
    
    args <- list(df)
    i <- 2
    while(i<length(key)+2) {
      args[[i]] <- df[[(key[[i-1]])]]
      i <- i + 1
    }
    
    df <- do.call(arrange, args)
    
    df <- df[reordered_colnames]
    
    return(df)
  }
}

generate_log_file <- function(df, key, filename, logname) {
  
  numeric_sum <- as.data.frame(cbind(colMean(dplyr::select_if(df,is.numeric)),
                                     colSD(dplyr::select_if(df,is.numeric)),
                                     colMin(dplyr::select_if(df,is.numeric)),
                                     colMax(dplyr::select_if(df,is.numeric))))
  
  all_sum <- as.data.frame(cbind(colSums(!is.na(df)), sapply(df, class)))
  
  summary_table <- merge(numeric_sum, all_sum, by="row.names", all = T)
  
  colnames <- c("variable", "mean", "sd", "min", "max", "N", "type")
  names(summary_table) <- colnames
  
  hash <- digest(df, algo="md5")
  
  if (!file.exists(logname)) {
    cat("\n", file = logname, append = F)
  } else {
    cat("\n", file = logname, append = T)
  }
    
  cat("==========================================================================", "\n", file = logname, append = T)
    
  cat("File:", filename, '\n', file = logname, append = T)
  cat("MD5: ", hash, '\n', file = logname, append = T)
  cat("Key: ", key, '\n', file = logname, append = T)
    
  s = capture.output(stargazer(summary_table, summary = F, type = 'text'))
  cat(paste(s,"\n"), file = logname, append = T)
  
  return("Log file generated successfully.")
}
