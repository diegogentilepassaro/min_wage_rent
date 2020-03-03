#source("save_data.R")
#source("load_packages.R")

library(foreign)
library(eeptools)
library(dplyr)
library(knitr)

load_packages = function(packages_names) {
  
  for(name in packages_names) {
    if (!(name %in% installed.packages())) {
      install.packages(name)
    }
    
    library(name, character.only = TRUE)
  }
}


save_data <- function(df, key, filename, logfile = NULL) {
  
  filetype <- substr(filename, nchar(filename) - 2, nchar(filename))
  dir      <- dirname(filename)
  
  df <- check_key(df, key)
  
  if (filetype == "csv") {
    print(filename)
    fwrite(df, file = filename)
    sprintf("File %s saved successfully.", filename)
    
  } else if (filetype == "dta") {
    
    write.dta(df, filename)
    sprintf("File %s saved successfully.", filename)
    
  } else {
    stop("Incorrect format. Only .csv and .dta are allowed.")
  }
  
  if (!is.null(logfile)) {
    generate_log_file(df, key, logfile)
  } else {
    generate_log_file(df, key, sprintf("%s/data_file_manifest.log", dir))
  }
}

check_key <- function(df, key) {
  
  df <- as.data.frame(df)
  
  if (!any(key %in% colnames(df))) {
    
    stop("KeyError: Key variables are not in df.")
    
  } else if (!isid(df, key)) {
    
    stop("KeyError: Key variables do not uniquely identify observations.")
    
  } else {
    
    reordered_colnames <- c(key, colnames(df[!colnames(df) %in% grep(paste0(key, collapse = "|"), key, value = T)]))
    
    df <- df[order(key), ]
    df <- df[reordered_colnames]
    
    return(list(df))
  }
}

generate_log_file <- function(df, key, filename) {
  
  df <- as.data.frame(df)
  df_summary <- t(sapply(df, summarize_var))
  
  if (!file.exists(filename)) {
    logfile <- file(filename, open = "w")
    
    writeLines("=====================================================\n", logfile)
    
    writeLines(sprintf("Filename: %s", filename), logfile)
    writeLines(sprintf("Key: %s\n", paste(key, collapse = ", ")), logfile)
    writeLines(kable(df_summary), logfile)
    writeLines("\n", logfile)
    
    writeLines("=====================================================\n", logfile)
    
  } else {
    
    old_logfile <- file(filename, open = "r")
    old_logfile_content <- readLines(old_logfile)
    close(old_logfile)
    
    logfile <- file(filename, open = "w")
    
    writeLines(old_logfile_content, logfile)
    writeLines("\n \n", logfile)
    
    writeLines("=====================================================\n", logfile)
    
    writeLines(sprintf("Filename: %s", filename), logfile)
    writeLines(sprintf("Key: %s\n", paste(key, collapse = ", ")), logfile)
    writeLines(kable(df_summary), logfile)
    writeLines("\n", logfile)
    
    writeLines("=====================================================\n", logfile)
  }  
  
  close(logfile)
  print("Log file generated successfully.")
}

summarize_var <- function(x, ...){
  if (typeof(x) == "double") {
    
    x_not_na <- x[!is.na(x)]
    
    as.numeric(round(
      c(mean   = mean(x_not_na, ...),
        sd     = sd(x_not_na, ...),
        min    = min(x_not_na, ...),
        median = median(x_not_na, ...),
        max    = max(x_not_na,...), 
        n      = length(x_not_na),
        na_count = length(x) - length(x_not_na))
      , 2))
    
  } else {
    
    c(mean   = "NA",
      sd     = "NA",
      median = "NA",
      min    = "NA",
      max    = "NA", 
      n      = "NA",
      na_count = length(x))
  }
}
