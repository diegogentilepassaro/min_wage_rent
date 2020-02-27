if (getwd()!= dirname(rstudioapi::getSourceEditorContext()$path)) setwd(dirname(rstudioapi::getSourceEditorContext()$path))

unlink("../temp", recursive = TRUE)
unlink("../output", recursive = TRUE)
dir.create("../temp/")
dir.create("../output/")

source('ReshapeMergeZillow_zip.R')
source('addMinWage.R')