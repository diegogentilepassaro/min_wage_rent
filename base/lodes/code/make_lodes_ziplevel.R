remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")

options(scipen=999)
load_packages(c('tidyverse', 'data.table', 'bit64', 'purrr', 'readxl'))

main <- function() {
  datadir_lodes <- '../../../drive/raw_data/lodes/'
  datadir_xwalk <- '../../../raw/crosswalk/'
  outdir <- '../../../drive/base_large/output/'
  
  xwalk <- make_xwalk(datadir_xwalk)
  
  tract_zip_xwalk <- read_excel(paste0(datadir_xwalk, "TRACT_ZIP_122012.xlsx"), 
                                col_names = c('tract_fips', 'zipcode', 'res_ratio', 'bus_ratio', 'oth_ratio', 'tot_ratio'),
                                col_types = c('numeric', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric'))
  tract_zip_xwalk <- setDT(tract_zip_xwalk)
  tract_zip_xwalk[, c('res_ratio', 'bus_ratio', 'oth_ratio'):= NULL]
  tract_zip_xwalk <- tract_zip_xwalk[!is.na(zipcode), ]
  
  
  #Datasets:
  # Point of View (pov) : statistics for either residents ('rac') or workers ('wac') in given geographies
  # Segment (seg)       : job earnings
  # Type (type)         : all jobs
  
  # Zipcode as workplace: all workers
  lodes_wac_all_all <- format_lodes(pov = 'wac', 
                                    seg = 'S000', 
                                    type = 'JT00', 
                                    vintage = '2017', 
                                    instub = datadir_lodes, 
                                    xw = xwalk, 
                                    xw_tractzip = tract_zip_xwalk)
  
  # Zipcode as residence: all workers
  lodes_rac_all_all <- format_lodes(pov = 'rac', 
                                    seg = 'S000', 
                                    type = 'JT00', 
                                    vintage = '2017', 
                                    instub = datadir_lodes, 
                                    xw = xwalk, 
                                    xw_tractzip = tract_zip_xwalk)
  
  # Zipcode as workplace: low income workers
  lodes_wac_el_all <- format_lodes(pov = 'wac', 
                                   seg = 'SE01', 
                                   type = 'JT00', 
                                   vintage = '2017', 
                                   instub = datadir_lodes, 
                                   xw = xwalk, 
                                   xw_tractzip = tract_zip_xwalk)
  
  # Zipcode as residence: low income workers
  lodes_rac_el_all <- format_lodes(pov = 'rac', 
                                   seg = 'SE01', 
                                   type = 'JT00', 
                                   vintage = '2017', 
                                   instub = datadir_lodes, 
                                   xw = xwalk, 
                                   xw_tractzip = tract_zip_xwalk)
  
  
  lodes_list <- list(lodes_wac_all_all, lodes_rac_all_all, lodes_wac_el_all, lodes_rac_el_all)
  
  lodes_final <- Reduce(function(x,y) merge(x,y, all = T, by = c('zipcode')), lodes_list)
  
  lodes_final <- make_final_vars(lodes_final)
  
  save_data(lodes_final, 
            filename = paste0(outdir, 'zip_lodes.csv'), 
            key = c('zipcode'))
  
  return(lodes_final)
}

make_final_vars <- function(data) {
  data[, walall_29y_lowinc_zsh := welall_njob_29young / walall_tot]
  data[, halall_29y_lowinc_zsh := helall_njob_29young / halall_tot]
  
  data[, c('w_sttot', 'h_sttot') :=lapply(.SD, function(x) sum(x, na.rm = T)), by = 'st', .SDcols = c('welall_njob_29young', 'helall_njob_29young')]

  data[, walall_29y_lowinc_ssh := lapply(.SD, function(x) x / w_sttot), .SDcols = c('welall_njob_29young')]
  data[, halall_29y_lowinc_ssh := lapply(.SD, function(x) x / h_sttot), .SDcols = c('helall_njob_29young')]
  
  data[, c('w_sttot', 'h_sttot') := NULL]
  
  vars <- c('walall_njob_29young_zsh', 
            'walall_njob_29young_ssh', 
            'halall_njob_29young_zsh', 
            'halall_njob_29young_ssh', 
            'welall_njob_29young_zsh', 
            'welall_njob_29young_ssh', 
            'walall_29y_lowinc_zsh', 
            'walall_29y_lowinc_ssh', 
            'halall_29y_lowinc_zsh', 
            'halall_29y_lowinc_ssh')
  
  vars <- c('zipcode', vars)
  
  data <- data[, ..vars]
  return(data)
  
}

make_xwalk <- function(instub) {
  xwalk_files <- list.files(paste0(instub, 'lodes/'), full.names = T)
  xwalk <- rbindlist(lapply(xwalk_files, function(x) fread(x)))
  setnames(xwalk, old = c('tabblk2010', 'trct'), new = c('blockfips', 'tract_fips'))
  target_xwalk <- c('blockfips', 'tract_fips', 'st')
  xwalk[, tract_fips := as.numeric(tract_fips)]
  xwalk <- xwalk[, ..target_xwalk]
  
  return(xwalk)
}

format_lodes <- function(pov, seg, type, vintage, instub, xw, xw_tractzip) {
  
  files <- list.files(paste0(instub, pov, '/', seg, '/', type, '/', vintage), full.names = T)
  files <- files[!grepl("Icon\r$", files)]
  
  df <- rbindlist(lapply(files, function(x) fread(x)))
  
  target_vars <- c('C000', 'CA01', 'CE01', 'CR02', 'CD01', 'CD02')
  target_names <- c('tot', 'njob_29young', 'njob_lowinc', 'njob_black', 'njob_nohs', 'njob_hs')
  final_names <- c('blockfips', target_names)
  if (pov=='rac') {
    setnames(df, old = c('h_geocode', target_vars), new = final_names)
  } else if (pov=='wac') {
    setnames(df, old = c('w_geocode', target_vars), new = final_names)
  }
  df <- df[, ..final_names]
  
  df[, 'njob_lowedu' := njob_nohs + njob_hs][, c('njob_nohs', 'njob_hs'):= NULL]
  target_names <- c(target_names[1:(length(target_names)-2)], 'njob_lowedu')
  
  dftract <- xw[df, on = 'blockfips'][, 'blockfips':= NULL]
  dftract <- dftract[, lapply(.SD,sum, na.rm = T),by=c('tract_fips', 'st')]
  
  dfzip <- dftract[xw_tractzip, on = 'tract_fips']
  dfzip <- dfzip[, lapply(.SD, function(x, w) sum(x*w, na.rm = T), w=tot_ratio), 
                  by = c('zipcode', 'st'), .SDcols = target_names]
  
  pr <- set_prefix(p = pov, s = seg, t = type)
  setnames(dfzip, old = target_names, new = paste(pr, target_names, sep = '_'))
  
  dfzip <- make_shares(data = dfzip, 
                        vnames = paste(pr, target_names, sep = '_'))
  
  sortvar <- names(dfzip)[grepl("tot$", names(dfzip))]
  setorderv(dfzip, c('zipcode',sortvar))
  dfzip <-  dfzip[dfzip[, .I[.N], zipcode]$V1]
  
  if ((pov!='rac') | (pov=='rac' & (seg!='S000' | type!='JT00'))) {
    dfzip[, st := NULL]
  }
  
  return(dfzip)
}

make_shares <- function(data, vnames, state.share = TRUE) {
  
  denom <- vnames[grepl("tot$", vnames)]
  vnames <- vnames[!grepl("tot$", vnames)]
  
  zsh_names <- paste0(vnames, '_zsh')
  
  data[, (zsh_names) := lapply(.SD, function(x) x / data[[denom]]), .SDcols = vnames]
  
  if (state.share == TRUE) {
    data[, st_tot:=lapply(.SD, function(x) sum(x, na.rm = T)), by = 'st', .SDcols = denom]
    ssh_names <- paste0(vnames, '_ssh')
    data[, (ssh_names) := lapply(.SD, function(x) x / st_tot), .SDcols = vnames]
    data[, st_tot := NULL]
  }
  #data[, (vnames) := NULL]
  
  return(data)
}

set_prefix <- function(p, s, t) {
  if (p=='rac') prefix <- 'h' else if (p=='wac') prefix <- 'w'
  
  if (s=='S000') {prefix <- paste0(prefix, 'al')}      # all jobs
  else if (s=="SE01") {prefix <- paste0(prefix, 'el')} # earnings lo w
  else if (s=='SE02') {prefix <- paste0(prefix, 'em')} # earnings med
  else if (s=='SE03') {prefix <- paste0(prefix, 'eh')} # earnings high
  else if (s=='SA01') {prefix <- paste0(prefix, 'ay')} # age young
  else if (s=='SA02') {prefix <- paste0(prefix, 'am')} # age med
  else if (s=='SA03') {prefix <- paste0(prefix, 'ao')} # age old
  else if (s=='SI01') {prefix <- paste0(prefix, 'ip')} # industry product, goods
  else if (s=='SI02') {prefix <- paste0(prefix, 'it')} # industry trade, transports
  else if (s=='SI03') {prefix <- paste0(prefix, 'io')} # industry other
  
  if (t=='JT00') {prefix <- paste0(prefix, 'all')}        # all jobs
  else if (t=='JT01') {prefix <- paste0(prefix, 'main')}  # main job s
  else if (t=='JT02') {prefix <- paste0(prefix, 'priv')}  # all private jobs
  else if (t=='JT03') {prefix <- paste0(prefix, 'mpriv')} # main private jobs
  else if (t=='JT04') {prefix <- paste0(prefix, 'fed')}   # federal job
  else if (t=='JT05') {prefix <- paste0(prefix, 'mfed')}  # main federal job
  
  
  return(prefix) 
}


#Execute
main()