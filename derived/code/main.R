if (getwd()!= dirname(rstudioapi::getSourceEditorContext()$path)) setwd(dirname(rstudioapi::getSourceEditorContext()$path))
outputdir <- "../output/"
file.remove(list.files(outputdir, include.dirs = F, full.names = T, recursive = T))

source('ReshapeMergeZillow_zip.R')