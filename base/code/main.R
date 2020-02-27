if (getwd()!= dirname(rstudioapi::getSourceEditorContext()$path)) setwd(dirname(rstudioapi::getSourceEditorContext()$path))

unlink("../temp", recursive = TRUE)
unlink("../output", recursive = TRUE)
dir.create("../temp/")
dir.create("../output/")

source("../../lib/R/check_packages.R")

# Rename Zillow Data
source("RenameZillowData_zip.R")

# Clean geography references
source('cleanGeoRelationshipFiles.R')

# Create minimum wage panels
# devtools::install_github('lbraglia/RStata')
# # check_packages('RStata')
# 
# options("RStata.StataPath" = "C:/Program Files (x86)/Stata15/StataMP-64")
# options("RStata.StataVersion" = 15)
# 
# # stata('help summarize')
# stata("state_mw.do")
