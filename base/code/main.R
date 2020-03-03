if (getwd()!= dirname(rstudioapi::getSourceEditorContext()$path)) setwd(dirname(rstudioapi::getSourceEditorContext()$path))

unlink("../temp", recursive = TRUE)
unlink("../output", recursive = TRUE)
dir.create("../temp/")
dir.create("../output/")

source("../../lib/R/load_packages.R")

source("RenameZillowVars_zipLevel.R")
rm(list = ls())

source('cleanGeoRelationshipFiles.R')
rm(list = ls())


