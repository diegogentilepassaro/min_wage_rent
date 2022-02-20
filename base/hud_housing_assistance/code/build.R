remove(list = ls())

library(data.table)
library(stringr)

`%notin%` <- Negate(`%in%`)

source("../../../lib/R/save_data.R")

main <- function () {
  in_hud <- '../../../drive/raw_data/hud_housing_assistance'
  outdir <- '../../../drive/base_large/hud_housing_assistance'
  
  vars <- fread('variables.csv', header = F)$V1
  
  geographies <- c("zipcode", "census_tract")
  
  for (gg in geographies) {
    files_path <- file.path(in_hud, gg)
    files_names <-
      list.files(files_path, pattern = ".xlsx", full.names = T)
    
    data <- rbindlist(lapply(files_names, function (x) {
      if (gg == "zipcode")      year <- as.integer(substr(x, 64, 67))
      if (gg == "census_tract") year <- as.integer(substr(x, 73, 76))
      
      data <- as.data.table(readxl::read_xlsx(x))[, year := year]
      
      setnames(data, "code", gg)
      
      vars_av <- intersect(names(data), vars)
      
      data <- manual_fixes(data, gg, year)
      
      return(data[, ..vars_av])
    }),
    fill = TRUE)
    
    save_data(
      data,
      key = c(gg, "program_label", "year"),
      filename = file.path(outdir, paste0(gg, ".csv")),
      logfile = file.path("../output", paste0(gg, "_data_manifest.log"))
    )
    save_data(
      data,
      key = c(gg, "program_label", "year"),
      filename = file.path(outdir, paste0(gg, ".dta")),
      nolog = TRUE
    )
  }
}

manual_fixes <- function(data, gg, year) {
  if (gg == "census_tract" & year == 2015) {
    data <-
      data[entities != "MO Missouri 186 Ste. Genevieve County 29186960200"]
  }
  
  for (col in names(data)) data[get(col) == -1, c(col):=0]
  
  data[spending_per_month < -5, spending_per_month := NA]
  data[total_units       == -2, total_units        := NA]
  
  data <- select_hud_programs(data)
  
  return(data)
}

select_hud_programs <- function(data,
                                progr_to_drop = c("Mod Rehab", "S236/BMIR")) {
  
  return(data[program_label %notin% progr_to_drop])
}

# Execute
main()
