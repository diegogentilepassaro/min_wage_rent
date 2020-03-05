library(foreign)
library(eeptools)
library(dplyr)
library(knitr)
library(skimr)

save_data <- function(df, key, filename, logfile = NULL, nolog = FALSE) {
  
  filetype <- substr(filename, nchar(filename) - 2, nchar(filename))
  dir      <- dirname(filename)
  
  df <- check_key(df, key)
  
  if (filetype == "csv") {
    
    fwrite(df, file = filename)
    print(paste0("File '", filename, "' saved successfully."))
    
  } else if (filetype == "dta") {
    
    write.dta(df, filename)
    print(paste0("File '", filename, "' saved successfully."))
    
  } else {
    stop("Incorrect format. Only .csv and .dta are allowed.")
  }
  
  if (!nolog) {
    if (!is.null(logfile)) {
      generate_log_file(df, key, filename, logfile)
    } else {
      generate_log_file(df, key, filename, sprintf("%s/data_file_manifest.log", dir))
    }
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
    
    df[with(df, order(key)), ]
    df <- df[reordered_colnames]
    
    return(df)
  }
}

generate_log_file <- function(df, key, filename, logname) {
  
  dim_df <- dim(df)
  
  df <- as.data.frame(df)

  skim_vars <- c("skim_variable", "skim_type", "n_missing", 
                 "character.min", "character.max", "character.n_unique",
                 "numeric.mean", "numeric.sd", "numeric.p0", "numeric.p50", "numeric.p100")
  df_summary <- as.data.frame(suppressWarnings(skim(df)[skim_vars]))
  
  colnames(df_summary) <- c("var", "type", "n_NA", "ch.min", "ch.max", "char.n_unique", 
                            "num.mean", "num.sd", "num.p0", "num.p50", "num.p100")
  
  if (!file.exists(logname)) {
    logfile <- file(logname, open = "w")
    
    writeLines("=========================================================================================", logfile)
    
    writeLines(sprintf("Filename: %s", filename), logfile)
    writeLines(sprintf("Key: %s.\nDimension: %s.\n", paste(key, collapse = ", "), 
               paste(dim_df, collapse = ' x ')), logfile)
    writeLines(kable(df_summary), logfile)
    writeLines("\n")

    writeLines("=========================================================================================\n", logfile)
    
  } else {
    
    old_logfile <- file(logname, open = "r")
    old_logfile_content <- readLines(old_logfile)
    close(old_logfile)
    
    logfile <- file(logname, open = "w")
    
    writeLines(old_logfile_content, logfile)

    writeLines("=========================================================================================", logfile)
    
    writeLines(sprintf("Filename: %s", filename), logfile)
    writeLines(sprintf("Key: %s.\nDimension: %s.\n", paste(key, collapse = ", "), 
                       paste(dim_df, collapse = ' x ')), logfile)
    writeLines(kable(df_summary), logfile)
    writeLines("\n")
    
    writeLines("=========================================================================================\n", logfile)
  }  
  
  print("Log file generated successfully.")
  close(logfile)
}

# summarize_var <- function(x, ...){
#   x_numeric <- as.numeric(x[1])
#   is_numeric <- typeof(x) == "numeric" | suppressWarnings(!is.na(x_numeric))
#   print(length(x))
#   if (is_numeric) {
# 
#     x <- as.numeric(x)
#     x_not_na <- x[!is.na(x)]
# 
#     as.numeric(round(
#       c(mean   = mean(x_not_na, ...),
#         sd     = sd(x_not_na, ...),
#         min    = min(x_not_na, ...),
#         median = median(x_not_na, ...),
#         max    = max(x_not_na,...),
#         n      = length(x_not_na),
#         na_count = length(x) - length(x_not_na))
#       , 2)
#     )
# 
#   } else {
# 
#     c(mean   = "NA",
#       sd     = "NA",
#       median = "NA",
#       min    = "NA",
#       max    = "NA",
#       n      = "NA",
#       na_count = length(x))
#   }
# }
