remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")

load_packages(c('tidyverse', 'data.table', 'tidycensus', 'bit64', 'readxl', 'lfe', 'ggplot2'))


main <- function() {
  
  data_version <- "0053"
  
  datadir  <- paste0("../../../drive/raw_data/census/tract/nhgis", data_version, "_csv/")
  xwalkdir <- "../../../raw/crosswalk/" 
  outdir   <- "../../../drive/base_large/demographics/"
  tempdir  <- "../temp"
  log_file <- "../output/data_file_manifest.log"
  
  table_list <- list.files(datadir, 
                           pattern = "*.csv")
  
  table_list <- str_remove_all(table_list, paste0("nhgis", data_version, "_"))
  
  table_clean <- lapply(table_list, format_tables, datadir = datadir, data_version = data_version)
  table_final <- Reduce(function(x,y) merge(x,y, all = T, by = c('tract_fips', 'county_fips')), table_clean)

  
  xwalk <- read_excel(paste0(xwalkdir, "TRACT_ZIP_122019.xlsx"), 
                      col_names = c('tract_fips', 'zipcode', 'res_ratio', 'bus_ratio', 'oth_ratio', 'tot_ratio'),
                      col_types = c('numeric', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric'))
  xwalk <- setDT(xwalk)
  xwalk[, c('res_ratio', 'bus_ratio', 'oth_ratio'):= NULL]
  xwalk <- xwalk[!is.na(zipcode), ]
  
  mw_avg1318 <- fread(paste0(tempdir, '/mw_avg1318.csv'))
  table_final <- mw_avg1318[table_final, on = 'tract_fips']

  table_final <- compute_mw_workers(table_final)
  
  mww_varlist <- c('mww_all2', 'mww_all1', 'mww_sub25_all2', 'mww_sub25_all1', 'mww_black_all2', 'mww_black_all1',
                   'mww_sub25_black_all1', 'mww_sub25_black_all2', 'mww_renter_all2', 'mww_renter_all1',
                   'hh1', 'hh2', 'hhTOT', 'hh1_white', 'hh1_black', 'hh2_white', 'hh2_black', 
                   'hh_blackTOT', 'hh_whiteTOT', 'hhincTOT', 'hhinc_sub25TOT', 'renthhTOT', 
                   'hh_1worker', 'hh_2worker', 'hh_workerTOT', 'hhinc_blackTOT', 'hhinc_whiteTOT', 
                   'hhinc_sub25_whiteTOT', 'hhinc_sub25_blackTOT', 'renthh_hunitsTOT', 'renthh_sub35_hunitsTOT', 
                   'hh_hunitsTOT', 'hh_sub35_hunitsTOT', 'renthh_single_hunitsTOT', 'renthh_couple_hunitsTOT', 
                   'hh_single_hunitsTOT', 'hh_couple_hunitsTOT', 'renthhinc_hunitsTOT', 
                   'mww_pt', 'mww_ft', 'mww', 'workers_ft', 'workers_pt')

  mww_varlist_tot <- c('tract_fips', 'county_fips', 'mw_annual_ft', 'mw_annual_ft2', 'mw_annual_pt', mww_varlist)     
    
  table_final <- table_final[, ..mww_varlist_tot]  

  table_final <- table_final[xwalk, on = 'tract_fips']

  table_final_zipshare <- table_final[, lapply(.SD, function(x, w) sum(x*w, na.rm = T), w=tot_ratio), by = 'zipcode', .SDcols = mww_varlist]

  table_final_zipshare[, c('sh_mww_all2',
                         'sh_mww_all1',
                         'mww_shsub25_all2', 
                         'mww_shsub25_all1',
                         'mww_shblack_all1',
                         'mww_shblack_all2', 
                         'mww_sub25_shblack_all1', 
                         'mww_sub25_shblack_all2',
                         'sh_mww_renter_all1',
                         'sh_mww_renter_all2', 
                         'mww_shrenter_all1',
                         'mww_shrenter_all2', 
                         'sh_hh1', 
                         'sh_hh2', 
                         'sh_white_hh1', 
                         'sh_white_hh2', 
                         'sh_black_hh1', 
                         'sh_black_hh2',
                         'sh_hh1worker',
                         'sh_hh2worker',
                         'sh_renthh_single', 
                         'sh_renthh_couple', 
                         'sh_renthh', 
                         'sh_mww_ft', 
                         'sh_mww_pt', 
                         'sh_mww') := list(
                          (mww_all2/hhTOT), 
                          (mww_all1/hhTOT),
                          (mww_sub25_all2/hhinc_sub25TOT), 
                          (mww_sub25_all1/hhinc_sub25TOT), 
                          (mww_black_all1/hh_blackTOT),
                          (mww_black_all2/hh_blackTOT),
                          (mww_sub25_black_all1/hh_blackTOT), 
                          (mww_sub25_black_all2/hh_blackTOT),
                          (mww_renter_all1/hh_hunitsTOT),
                          (mww_renter_all2/hh_hunitsTOT), 
                          (mww_renter_all1/renthhinc_hunitsTOT),
                          (mww_renter_all2/renthhinc_hunitsTOT), 
                          (hh1/hhTOT), 
                          (hh2/hhTOT), 
                          (hh1_white/hh_whiteTOT), 
                          (hh2_white/hh_whiteTOT),
                          (hh1_black/hh_blackTOT),
                          (hh2_black/hh_blackTOT),
                          (hh_1worker/hh_workerTOT),
                          (hh_2worker/hh_workerTOT),
                          (renthh_single_hunitsTOT/renthh_hunitsTOT), 
                          (renthh_couple_hunitsTOT/renthh_hunitsTOT),
                          (renthh_hunitsTOT/hh_hunitsTOT), 
                          (mww_ft / workers_ft), 
                          (mww_pt / workers_pt), 
                          (mww / (workers_ft + workers_pt)))]

  table_final_zipshare[, c('sh_mww_wmean1',
                         'sh_mww_wmean2',
                         'mww_shrenter_wmean1',
                         'mww_shrenter_wmean2',
                         'sh_mww_renter_wmean1', 
                         'sh_mww_renter_wmean2') := list(
                           (((mww_all1*sh_hh1) + (mww_all2*sh_hh2))/hhTOT),
                           (((mww_all1*sh_hh1worker) + (mww_all2*sh_hh2worker))/hhTOT),
                           (((mww_renter_all1*sh_renthh_single) + (mww_renter_all2*sh_renthh_couple))/renthh_hunitsTOT),
                           (((mww_renter_all1*sh_hh1worker) + (mww_renter_all2*sh_hh2worker))/renthh_hunitsTOT),
                           (((mww_renter_all1*sh_renthh_single) + (mww_renter_all2*sh_renthh_couple))/hh_hunitsTOT), 
                           (((mww_renter_all1*sh_hh1worker) + (mww_renter_all2*sh_hh2worker))/hh_hunitsTOT))]


  table_final_zipshare <- table_final_zipshare[, c('zipcode',
                                                 'sh_mww_all1', 'sh_mww_all2', 'sh_mww_wmean1', 'sh_mww_wmean2', 
                                                 'mww_shsub25_all1', 'mww_shsub25_all2', 
                                                 'mww_shblack_all1', 'mww_shblack_all2', 'mww_sub25_shblack_all1', 'mww_sub25_shblack_all2', 
                                                 'sh_mww_renter_all1', 'sh_mww_renter_all2', 'sh_mww_renter_wmean1', 'sh_mww_renter_wmean2', 
                                                 'mww_shrenter_all1', 'mww_shrenter_all2',  'mww_shrenter_wmean1', 'mww_shrenter_wmean2', 
                                                 'sh_mww_ft', 'sh_mww_pt', 'sh_mww', 'workers_pt', 'workers_ft')]

  save_data(df = table_final_zipshare, key = 'zipcode', 
          filename = paste0(outdir, 'zip_mw.csv'),
          logfile  = log_file)
}

compute_mw_workers <- function(data){
  
 data[mw_annual_ft<=3750, mww_ft := .(pinc_ft_0_25)][
   mw_annual_ft>3750 & mw_annual_ft<=6250, mww_ft := .(pinc_ft_0_25 + pinc_ft_25_50)][
     mw_annual_ft>6250 & mw_annual_ft<=8750, mww_ft := .(pinc_ft_0_25 + pinc_ft_25_50 + pinc_ft_50_75)][
       mw_annual_ft>8750 & mw_annual_ft<=11250, mww_ft := .(pinc_ft_0_25 + pinc_ft_25_50 + pinc_ft_50_75 + pinc_ft_75_100)][
         mw_annual_ft>11250 & mw_annual_ft<=13750, mww_ft := .(pinc_ft_0_25 + pinc_ft_25_50 + pinc_ft_50_75 + pinc_ft_75_100 + pinc_ft_100_125)][
           mw_annual_ft>13750 & mw_annual_ft<=16250, mww_ft := .(pinc_ft_0_25 + pinc_ft_25_50 + pinc_ft_50_75 + pinc_ft_75_100 + pinc_ft_100_125 + pinc_ft_125_150)][
             mw_annual_ft>16250 & mw_annual_ft<=18750, mww_ft := .(pinc_ft_0_25 + pinc_ft_25_50 + pinc_ft_50_75 + pinc_ft_75_100 + pinc_ft_100_125 + pinc_ft_125_150 + pinc_ft_150_175)][
               mw_annual_ft>18750 & mw_annual_ft<=21250, mww_ft := .(pinc_ft_0_25 + pinc_ft_25_50 + pinc_ft_50_75 + pinc_ft_75_100 + pinc_ft_100_125 + pinc_ft_125_150 + pinc_ft_150_175 + pinc_ft_175_200)][
                 mw_annual_ft>21250 & mw_annual_ft<=23750, mww_ft := .(pinc_ft_0_25 + pinc_ft_25_50 + pinc_ft_50_75 + pinc_ft_75_100 + pinc_ft_100_125 + pinc_ft_125_150 + pinc_ft_150_175 + pinc_ft_175_200 + pinc_ft_200_225)][
                   mw_annual_ft>23750 & mw_annual_ft<=26250, mww_ft := .(pinc_ft_0_25 + pinc_ft_25_50 + pinc_ft_50_75 + pinc_ft_75_100 + pinc_ft_100_125 + pinc_ft_125_150 + pinc_ft_150_175 + pinc_ft_175_200 + pinc_ft_200_225 + pinc_ft_225_250)][
                     mw_annual_ft>26250 , mww_ft := .(pinc_ft_0_25 + pinc_ft_25_50 + pinc_ft_50_75 + pinc_ft_75_100 + pinc_ft_100_125 + pinc_ft_125_150 + pinc_ft_150_175 + pinc_ft_175_200 + pinc_ft_200_225 + pinc_ft_225_250 + pinc_ft_250_300)] 
 
  data[mw_annual_pt<=3750, mww_pt := .(pinc_pt_0_25)][
   mw_annual_pt>3750 & mw_annual_pt<=6250, mww_pt := .(pinc_pt_0_25 + pinc_pt_25_50)][
     mw_annual_pt>6250 & mw_annual_pt<=8750, mww_pt := .(pinc_pt_0_25 + pinc_pt_25_50 + pinc_pt_50_75)][
       mw_annual_pt>8750 & mw_annual_pt<=11250, mww_pt := .(pinc_pt_0_25 + pinc_pt_25_50 + pinc_pt_50_75 + pinc_pt_75_100)][
         mw_annual_pt>11250 & mw_annual_pt<=13750, mww_pt := .(pinc_pt_0_25 + pinc_pt_25_50 + pinc_pt_50_75 + pinc_pt_75_100 + pinc_pt_100_125)][
           mw_annual_pt>13750, mww_pt := .(pinc_pt_0_25 + pinc_pt_25_50 + pinc_pt_50_75 + pinc_pt_75_100 + pinc_pt_100_125 + pinc_pt_125_150)] 
  
  data[, 'mww' := .(mww_ft + mww_pt)]
  
  data[mw_annual_ft2<=17500 , mww_all2 := .(hhinc_0_15)][
    mw_annual_ft2>17500 & mw_annual_ft2<=22500, mww_all2 := .(hhinc_0_15 + hhinc_15_20)][
      mw_annual_ft2>22500 & mw_annual_ft2<=27500, mww_all2 := .(hhinc_0_15 + hhinc_15_20 + hhinc_20_25)][
        mw_annual_ft2>27500 & mw_annual_ft2<=32500, mww_all2 := .(hhinc_0_15 + hhinc_15_20 + hhinc_20_25 + hhinc_25_30)][
          mw_annual_ft2>32500 & mw_annual_ft2<=37500, mww_all2 := .(hhinc_0_15 + hhinc_15_20 + hhinc_20_25 + hhinc_25_30 + hhinc_30_35)][
            mw_annual_ft2>37500 & mw_annual_ft2<=42500, mww_all2 := .(hhinc_0_15 + hhinc_15_20 + hhinc_20_25 + hhinc_25_30 + hhinc_30_35 + hhinc_35_40)][
              mw_annual_ft2>42500 & mw_annual_ft2<=47500, mww_all2 := .(hhinc_0_15 + hhinc_15_20 + hhinc_20_25 + hhinc_25_30 + hhinc_30_35 + hhinc_35_40 + hhinc_40_45)][
                mw_annual_ft2>47500 & mw_annual_ft2<=52500, mww_all2 := .(hhinc_0_15 + hhinc_15_20 + hhinc_20_25 + hhinc_25_30 + hhinc_30_35 + hhinc_35_40 + hhinc_40_45 + hhinc_45_50)][
                  mw_annual_ft2>52500 & mw_annual_ft2<=65000, mww_all2 := .(hhinc_0_15 + hhinc_15_20 + hhinc_20_25 + hhinc_25_30 + hhinc_30_35 + hhinc_35_40 + hhinc_40_45 + hhinc_45_50 + hhinc_50_60)]

  data[mw_annual_ft<=17500 , mww_all1 := .(hhinc_0_15)][
    mw_annual_ft>17500 & mw_annual_ft<=22500, mww_all1 := .(hhinc_0_15 + hhinc_15_20)][
      mw_annual_ft>22500 & mw_annual_ft<=27500, mww_all1 := .(hhinc_0_15 + hhinc_15_20 + hhinc_20_25)][
        mw_annual_ft>27500 & mw_annual_ft<=32500, mww_all1 := .(hhinc_0_15 + hhinc_15_20 + hhinc_20_25 + hhinc_25_30)][
          mw_annual_ft>32500 & mw_annual_ft<=37500, mww_all1 := .(hhinc_0_15 + hhinc_15_20 + hhinc_20_25 + hhinc_25_30 + hhinc_30_35)][
            mw_annual_ft>37500 & mw_annual_ft<=42500, mww_all1 := .(hhinc_0_15 + hhinc_15_20 + hhinc_20_25 + hhinc_25_30 + hhinc_30_35 + hhinc_35_40)][
              mw_annual_ft>42500 & mw_annual_ft<=47500, mww_all1 := .(hhinc_0_15 + hhinc_15_20 + hhinc_20_25 + hhinc_25_30 + hhinc_30_35 + hhinc_35_40 + hhinc_40_45)][
                mw_annual_ft>47500 & mw_annual_ft<=52500, mww_all1 := .(hhinc_0_15 + hhinc_15_20 + hhinc_20_25 + hhinc_25_30 + hhinc_30_35 + hhinc_35_40 + hhinc_40_45 + hhinc_45_50)][
                  mw_annual_ft>52500 & mw_annual_ft<=65000, mww_all1 := .(hhinc_0_15 + hhinc_15_20 + hhinc_20_25 + hhinc_25_30 + hhinc_30_35 + hhinc_35_40 + hhinc_40_45 + hhinc_45_50 + hhinc_50_60)]
  
    
  data[mw_annual_ft2<=17500 , mww_sub25_all2 := .(hhinc_sub25_0_15)][
    mw_annual_ft2>17500 & mw_annual_ft2<=22500, mww_sub25_all2 := .(hhinc_sub25_0_15 + hhinc_sub25_15_20)][
      mw_annual_ft2>22500 & mw_annual_ft2<=27500, mww_sub25_all2 := .(hhinc_sub25_0_15 + hhinc_sub25_15_20 + hhinc_sub25_20_25)][
        mw_annual_ft2>27500 & mw_annual_ft2<=32500, mww_sub25_all2 := .(hhinc_sub25_0_15 + hhinc_sub25_15_20 + hhinc_sub25_20_25 + hhinc_sub25_25_30)][
          mw_annual_ft2>32500 & mw_annual_ft2<=37500, mww_sub25_all2 := .(hhinc_sub25_0_15 + hhinc_sub25_15_20 + hhinc_sub25_20_25 + hhinc_sub25_25_30 + hhinc_sub25_30_35)][
            mw_annual_ft2>37500 & mw_annual_ft2<=42500, mww_sub25_all2 := .(hhinc_sub25_0_15 + hhinc_sub25_15_20 + hhinc_sub25_20_25 + hhinc_sub25_25_30 + hhinc_sub25_30_35 + hhinc_sub25_35_40)][
              mw_annual_ft2>42500 & mw_annual_ft2<=47500, mww_sub25_all2 := .(hhinc_sub25_0_15 + hhinc_sub25_15_20 + hhinc_sub25_20_25 + hhinc_sub25_25_30 + hhinc_sub25_30_35 + hhinc_sub25_35_40 + hhinc_sub25_40_45)][
                mw_annual_ft2>47500 & mw_annual_ft2<=52500, mww_sub25_all2 := .(hhinc_sub25_0_15 + hhinc_sub25_15_20 + hhinc_sub25_20_25 + hhinc_sub25_25_30 + hhinc_sub25_30_35 + hhinc_sub25_35_40 + hhinc_sub25_40_45 + hhinc_sub25_45_50)][
                  mw_annual_ft2>52500 & mw_annual_ft2<=65000, mww_sub25_all2 := .(hhinc_sub25_0_15 + hhinc_sub25_15_20 + hhinc_sub25_20_25 + hhinc_sub25_25_30 + hhinc_sub25_30_35 + hhinc_sub25_35_40 + hhinc_sub25_40_45 + hhinc_sub25_45_50 + hhinc_sub25_50_60)]
  
  data[mw_annual_ft<=17500 , mww_sub25_all1 := .(hhinc_sub25_0_15)][
    mw_annual_ft>17500 & mw_annual_ft<=22500, mww_sub25_all1 := .(hhinc_sub25_0_15 + hhinc_sub25_15_20)][
      mw_annual_ft>22500 & mw_annual_ft<=27500, mww_sub25_all1 := .(hhinc_sub25_0_15 + hhinc_sub25_15_20 + hhinc_sub25_20_25)][
        mw_annual_ft>27500 & mw_annual_ft<=32500, mww_sub25_all1 := .(hhinc_sub25_0_15 + hhinc_sub25_15_20 + hhinc_sub25_20_25 + hhinc_sub25_25_30)][
          mw_annual_ft>32500 & mw_annual_ft<=37500, mww_sub25_all1 := .(hhinc_sub25_0_15 + hhinc_sub25_15_20 + hhinc_sub25_20_25 + hhinc_sub25_25_30 + hhinc_sub25_30_35)][
            mw_annual_ft>37500 & mw_annual_ft<=42500, mww_sub25_all1 := .(hhinc_sub25_0_15 + hhinc_sub25_15_20 + hhinc_sub25_20_25 + hhinc_sub25_25_30 + hhinc_sub25_30_35 + hhinc_sub25_35_40)][
              mw_annual_ft>42500 & mw_annual_ft<=47500, mww_sub25_all1 := .(hhinc_sub25_0_15 + hhinc_sub25_15_20 + hhinc_sub25_20_25 + hhinc_sub25_25_30 + hhinc_sub25_30_35 + hhinc_sub25_35_40 + hhinc_sub25_40_45)][
                mw_annual_ft>47500 & mw_annual_ft<=52500, mww_sub25_all1 := .(hhinc_sub25_0_15 + hhinc_sub25_15_20 + hhinc_sub25_20_25 + hhinc_sub25_25_30 + hhinc_sub25_30_35 + hhinc_sub25_35_40 + hhinc_sub25_40_45 + hhinc_sub25_45_50)][
                  mw_annual_ft>52500 & mw_annual_ft<=65000, mww_sub25_all1 := .(hhinc_sub25_0_15 + hhinc_sub25_15_20 + hhinc_sub25_20_25 + hhinc_sub25_25_30 + hhinc_sub25_30_35 + hhinc_sub25_35_40 + hhinc_sub25_40_45 + hhinc_sub25_45_50 + hhinc_sub25_50_60)]
  
  data[mw_annual_ft2<=17500 , mww_black_all2 := .(hhinc_black_0_15)][
    mw_annual_ft2>17500 & mw_annual_ft2<=22500, mww_black_all2 := .(hhinc_black_0_15 + hhinc_black_15_20)][
      mw_annual_ft2>22500 & mw_annual_ft2<=27500, mww_black_all2 := .(hhinc_black_0_15 + hhinc_black_15_20 + hhinc_black_20_25)][
        mw_annual_ft2>27500 & mw_annual_ft2<=32500, mww_black_all2 := .(hhinc_black_0_15 + hhinc_black_15_20 + hhinc_black_20_25 + hhinc_black_25_30)][
          mw_annual_ft2>32500 & mw_annual_ft2<=37500, mww_black_all2 := .(hhinc_black_0_15 + hhinc_black_15_20 + hhinc_black_20_25 + hhinc_black_25_30 + hhinc_black_30_35)][
            mw_annual_ft2>37500 & mw_annual_ft2<=42500, mww_black_all2 := .(hhinc_black_0_15 + hhinc_black_15_20 + hhinc_black_20_25 + hhinc_black_25_30 + hhinc_black_30_35 + hhinc_black_35_40)][
              mw_annual_ft2>42500 & mw_annual_ft2<=47500, mww_black_all2 := .(hhinc_black_0_15 + hhinc_black_15_20 + hhinc_black_20_25 + hhinc_black_25_30 + hhinc_black_30_35 + hhinc_black_35_40 + hhinc_black_40_45)][
                mw_annual_ft2>47500 & mw_annual_ft2<=52500, mww_black_all2 := .(hhinc_black_0_15 + hhinc_black_15_20 + hhinc_black_20_25 + hhinc_black_25_30 + hhinc_black_30_35 + hhinc_black_35_40 + hhinc_black_40_45 + hhinc_black_45_50)][
                  mw_annual_ft2>52500 & mw_annual_ft2<=65000, mww_black_all2 := .(hhinc_black_0_15 + hhinc_black_15_20 + hhinc_black_20_25 + hhinc_black_25_30 + hhinc_black_30_35 + hhinc_black_35_40 + hhinc_black_40_45 + hhinc_black_45_50 + hhinc_black_50_60)]  

  data[mw_annual_ft<=17500 , mww_black_all1 := .(hhinc_black_0_15)][
    mw_annual_ft>17500 & mw_annual_ft<=22500, mww_black_all1 := .(hhinc_black_0_15 + hhinc_black_15_20)][
      mw_annual_ft>22500 & mw_annual_ft<=27500, mww_black_all1 := .(hhinc_black_0_15 + hhinc_black_15_20 + hhinc_black_20_25)][
        mw_annual_ft>27500 & mw_annual_ft<=32500, mww_black_all1 := .(hhinc_black_0_15 + hhinc_black_15_20 + hhinc_black_20_25 + hhinc_black_25_30)][
          mw_annual_ft>32500 & mw_annual_ft<=37500, mww_black_all1 := .(hhinc_black_0_15 + hhinc_black_15_20 + hhinc_black_20_25 + hhinc_black_25_30 + hhinc_black_30_35)][
            mw_annual_ft>37500 & mw_annual_ft<=42500, mww_black_all1 := .(hhinc_black_0_15 + hhinc_black_15_20 + hhinc_black_20_25 + hhinc_black_25_30 + hhinc_black_30_35 + hhinc_black_35_40)][
              mw_annual_ft>42500 & mw_annual_ft<=47500, mww_black_all1 := .(hhinc_black_0_15 + hhinc_black_15_20 + hhinc_black_20_25 + hhinc_black_25_30 + hhinc_black_30_35 + hhinc_black_35_40 + hhinc_black_40_45)][
                mw_annual_ft>47500 & mw_annual_ft<=52500, mww_black_all1 := .(hhinc_black_0_15 + hhinc_black_15_20 + hhinc_black_20_25 + hhinc_black_25_30 + hhinc_black_30_35 + hhinc_black_35_40 + hhinc_black_40_45 + hhinc_black_45_50)][
                  mw_annual_ft>52500 & mw_annual_ft<=65000, mww_black_all1 := .(hhinc_black_0_15 + hhinc_black_15_20 + hhinc_black_20_25 + hhinc_black_25_30 + hhinc_black_30_35 + hhinc_black_35_40 + hhinc_black_40_45 + hhinc_black_45_50 + hhinc_black_50_60)]    
  
  data[mw_annual_ft<=17500 , mww_sub25_black_all1 := .(hhinc_sub25_black_0_15)][
    mw_annual_ft>17500 & mw_annual_ft<=22500, mww_sub25_black_all1 := .(hhinc_sub25_black_0_15 + hhinc_sub25_black_15_20)][
      mw_annual_ft>22500 & mw_annual_ft<=27500, mww_sub25_black_all1 := .(hhinc_sub25_black_0_15 + hhinc_sub25_black_15_20 + hhinc_sub25_black_20_25)][
        mw_annual_ft>27500 & mw_annual_ft<=32500, mww_sub25_black_all1 := .(hhinc_sub25_black_0_15 + hhinc_sub25_black_15_20 + hhinc_sub25_black_20_25 + hhinc_sub25_black_25_30)][
          mw_annual_ft>32500 & mw_annual_ft<=37500, mww_sub25_black_all1 := .(hhinc_sub25_black_0_15 + hhinc_sub25_black_15_20 + hhinc_sub25_black_20_25 + hhinc_sub25_black_25_30 + hhinc_sub25_black_30_35)][
            mw_annual_ft>37500 & mw_annual_ft<=42500, mww_sub25_black_all1 := .(hhinc_sub25_black_0_15 + hhinc_sub25_black_15_20 + hhinc_sub25_black_20_25 + hhinc_sub25_black_25_30 + hhinc_sub25_black_30_35 + hhinc_sub25_black_35_40)][
              mw_annual_ft>42500 & mw_annual_ft<=47500, mww_sub25_black_all1 := .(hhinc_sub25_black_0_15 + hhinc_sub25_black_15_20 + hhinc_sub25_black_20_25 + hhinc_sub25_black_25_30 + hhinc_sub25_black_30_35 + hhinc_sub25_black_35_40 + hhinc_sub25_black_40_45)][
                mw_annual_ft>47500 & mw_annual_ft<=52500, mww_sub25_black_all1 := .(hhinc_sub25_black_0_15 + hhinc_sub25_black_15_20 + hhinc_sub25_black_20_25 + hhinc_sub25_black_25_30 + hhinc_sub25_black_30_35 + hhinc_sub25_black_35_40 + hhinc_sub25_black_40_45 + hhinc_sub25_black_45_50)][
                  mw_annual_ft>52500 & mw_annual_ft<=65000, mww_sub25_black_all1 := .(hhinc_sub25_black_0_15 + hhinc_sub25_black_15_20 + hhinc_sub25_black_20_25 + hhinc_sub25_black_25_30 + hhinc_sub25_black_30_35 + hhinc_sub25_black_35_40 + hhinc_sub25_black_40_45 + hhinc_sub25_black_45_50 + hhinc_sub25_black_50_60)]
  
  data[mw_annual_ft2<=17500 , mww_sub25_black_all2 := .(hhinc_sub25_black_0_15)][
    mw_annual_ft2>17500 & mw_annual_ft2<=22500, mww_sub25_black_all2 := .(hhinc_sub25_black_0_15 + hhinc_sub25_black_15_20)][
      mw_annual_ft2>22500 & mw_annual_ft2<=27500, mww_sub25_black_all2 := .(hhinc_sub25_black_0_15 + hhinc_sub25_black_15_20 + hhinc_sub25_black_20_25)][
        mw_annual_ft2>27500 & mw_annual_ft2<=32500, mww_sub25_black_all2 := .(hhinc_sub25_black_0_15 + hhinc_sub25_black_15_20 + hhinc_sub25_black_20_25 + hhinc_sub25_black_25_30)][
          mw_annual_ft2>32500 & mw_annual_ft2<=37500, mww_sub25_black_all2 := .(hhinc_sub25_black_0_15 + hhinc_sub25_black_15_20 + hhinc_sub25_black_20_25 + hhinc_sub25_black_25_30 + hhinc_sub25_black_30_35)][
            mw_annual_ft2>37500 & mw_annual_ft2<=42500, mww_sub25_black_all2 := .(hhinc_sub25_black_0_15 + hhinc_sub25_black_15_20 + hhinc_sub25_black_20_25 + hhinc_sub25_black_25_30 + hhinc_sub25_black_30_35 + hhinc_sub25_black_35_40)][
              mw_annual_ft2>42500 & mw_annual_ft2<=47500, mww_sub25_black_all2 := .(hhinc_sub25_black_0_15 + hhinc_sub25_black_15_20 + hhinc_sub25_black_20_25 + hhinc_sub25_black_25_30 + hhinc_sub25_black_30_35 + hhinc_sub25_black_35_40 + hhinc_sub25_black_40_45)][
                mw_annual_ft2>47500 & mw_annual_ft2<=52500, mww_sub25_black_all2 := .(hhinc_sub25_black_0_15 + hhinc_sub25_black_15_20 + hhinc_sub25_black_20_25 + hhinc_sub25_black_25_30 + hhinc_sub25_black_30_35 + hhinc_sub25_black_35_40 + hhinc_sub25_black_40_45 + hhinc_sub25_black_45_50)][
                  mw_annual_ft2>52500 & mw_annual_ft2<=65000, mww_sub25_black_all2 := .(hhinc_sub25_black_0_15 + hhinc_sub25_black_15_20 + hhinc_sub25_black_20_25 + hhinc_sub25_black_25_30 + hhinc_sub25_black_30_35 + hhinc_sub25_black_35_40 + hhinc_sub25_black_40_45 + hhinc_sub25_black_45_50 + hhinc_sub25_black_50_60)]
  
  
  data[mw_annual_ft2<=17500 , mww_renter_all2 := .(hhinc_0_15)][
    mw_annual_ft2>17500 & mw_annual_ft2<=22500, mww_renter_all2 := .(renthhinc_0_15 + renthhinc_15_20)][
      mw_annual_ft2>22500 & mw_annual_ft2<=27500, mww_renter_all2 := .(renthhinc_0_15 + renthhinc_15_20 + renthhinc_20_25)][
        mw_annual_ft2>27500 & mw_annual_ft2<=42500, mww_renter_all2 := .(renthhinc_0_15 + renthhinc_15_20 + renthhinc_20_25 + renthhinc_25_35)][
          mw_annual_ft2>42500 & mw_annual_ft2<=57500, mww_renter_all2 := .(renthhinc_0_15 + renthhinc_15_20 + renthhinc_20_25 + renthhinc_25_35 + renthhinc_35_50)][
            mw_annual_ft2>57500, mww_renter_all2 := .(renthhinc_0_15 + renthhinc_15_20 + renthhinc_20_25 + renthhinc_25_35 + renthhinc_35_50)]
 
  data[mw_annual_ft<=17500 , mww_renter_all1 := .(hhinc_0_15)][
    mw_annual_ft>17500 & mw_annual_ft<=22500, mww_renter_all1 := .(renthhinc_0_15 + renthhinc_15_20)][
      mw_annual_ft>22500 & mw_annual_ft<=27500, mww_renter_all1 := .(renthhinc_0_15 + renthhinc_15_20 + renthhinc_20_25)][
        mw_annual_ft>27500 & mw_annual_ft<=42500, mww_renter_all1 := .(renthhinc_0_15 + renthhinc_15_20 + renthhinc_20_25 + renthhinc_25_35)][
          mw_annual_ft>42500 & mw_annual_ft<=57500, mww_renter_all1 := .(renthhinc_0_15 + renthhinc_15_20 + renthhinc_20_25 + renthhinc_25_35 + renthhinc_35_50)][
            mw_annual_ft>57500, mww_renter_all1 := .(renthhinc_0_15 + renthhinc_15_20 + renthhinc_20_25 + renthhinc_25_35 + renthhinc_35_50)]
  
   
  return(data)
}


format_tables <- function(x, datadir, data_version) {
  data <- fread(paste0(datadir, "nhgis", data_version, "_", x))
  
  make_geo <-  function(y) {
    if (class(y)[1] != "data.table") y <- setDT(y)
    
    y[, c('tract_fips', 'county_fips') := list(
      as.numeric(paste0(
        str_pad(STATEA, 2, pad = "0"),
        str_pad(COUNTYA, 3, pad = "0"),
        str_pad(TRACTA, 6, pad = "0"))),
      as.numeric(paste0(str_pad(STATEA, 2, pad = "0"),
                        str_pad(COUNTYA, 3, pad = "0"))))]
    setnames(y, old = "CBSAA", new = "cbsa")
    
    return(y)
  }
  data <- make_geo(data)
  
  if (x == "ds239_20185_2018_tract.csv") {
    
    data[, c('hh2', 
             'hh1', 
             'hhTOT', 
             'hh2_black', 
             'hh1_black', 
             'hh_blackTOT', 
             'hh2_white', 
             'hh1_white', 
             'hh_whiteTOT') := 
           list((AJXKE003 + AJXKE009),
                (AJXKE004 + AJXKE008) , 
                (AJXKE001), 
                (AJXME003 + AJXME009),
                (AJXME004 + AJXME008) , 
                (AJXME001), 
                (AJXSE003 + AJXSE009),
                (AJXSE004 + AJXSE008) , 
                (AJXSE001))]
    
    data[, c('hhinc_0_15', 
             'hhinc_15_20', 
             'hhinc_20_25', 
             'hhinc_25_30', 
             'hhinc_30_35',
             'hhinc_35_40', 
             'hhinc_40_45',
             'hhinc_45_50',
             'hhinc_50_60',
             'hhinc_60_', 
             'hhincTOT') :=
           list((AJY9E002 + AJY9E003), 
                (AJY9E004), 
                (AJY9E005),
                (AJY9E006), 
                (AJY9E007), 
                (AJY9E008), 
                (AJY9E009), 
                (AJY9E010), 
                (AJY9E011), 
                (AJY9E012 + AJY9E013 + AJY9E014 + AJY9E015 + AJY9E016 + AJY9E017), 
                (AJY9E001))]
    
    data[, c('hhinc_sub25_0_15', 
             'hhinc_sub25_15_20', 
             'hhinc_sub25_20_25', 
             'hhinc_sub25_25_30', 
             'hhinc_sub25_30_35', 
             'hhinc_sub25_35_40', 
             'hhinc_sub25_40_45', 
             'hhinc_sub25_45_50', 
             'hhinc_sub25_50_60', 
             'hhinc_sub25_60_', 
             'hhinc_sub25TOT') := 
           list((AJZLE003 + AJZLE004), 
                (AJZLE005), 
                (AJZLE006),
                (AJZLE007), 
                (AJZLE008), 
                (AJZLE009), 
                (AJZLE010), 
                (AJZLE011), 
                (AJZLE012), 
                (AJZLE013 + AJZLE014 + AJZLE015 + AJZLE016 + AJZLE017 + AJZLE018), 
                (AJZLE002))]
    
    data[, c('workers_ft', 'workers_pt') := list((AJ1EE004 + AJ1EE009 + AJ1EE014 + AJ1EE019 + AJ1EE024 + AJ1EE029 + AJ1EE034), 
                                                 (AJ1EE005 + AJ1EE010 + AJ1EE015 + AJ1EE020 + AJ1EE025 + AJ1EE030 + AJ1EE035))] 
    
    data[, c('pop_rent_share', 'pop_rent_shareD') := list(AJ17E003, AJ17E001)]
    
    data[, c('renthh_grent_incshare_0_10', 
             'renthh_grent_incshare_10_15', 
             'renthh_grent_incshare_15_20', 
             'renthh_grent_incshare_20_25', 
             'renthh_grent_incshare_25_30', 
             'renthh_grent_incshare_30_35', 
             'renthh_grent_incshare_35_40', 
             'renthh_grent_incshare_40_50', 
             'renthh_grent_incshare_50_', 
             'renthhTOT') := 
           list((AJ3KE002), 
                (AJ3KE003), 
                (AJ3KE004), 
                (AJ3KE005), 
                (AJ3KE006), 
                (AJ3KE007), 
                (AJ3KE008), 
                (AJ3KE009), 
                (AJ3KE010),
                (AJ3KE001))]
    
    data[, c('renthhinc_0_10_sh0_30', 
             'renthhinc_0_10_sh30_', 
             'renthhinc_10_20_sh0_30', 
             'renthhinc_10_20_sh30_', 
             'renthhinc_20_35_sh0_30', 
             'renthhinc_20_35_sh30_', 
             'renthhinc_35_50_sh0_30', 
             'renthhinc_35_50_sh30_', 
             'renthhinc_50_sh0_30', 
             'renthhinc_50_sh30_') := 
           list((AJ3NE003 + AJ3NE004 + AJ3NE005), 
                (AJ3NE006 + AJ3NE007 + AJ3NE008 + AJ3NE009), 
                (AJ3NE012 + AJ3NE013 + AJ3NE014), 
                (AJ3NE015 + AJ3NE016 + AJ3NE017 + AJ3NE018), 
                (AJ3NE021 + AJ3NE022 + AJ3NE023), 
                (AJ3NE024 + AJ3NE025 + AJ3NE026 + AJ3NE027), 
                (AJ3NE030 + AJ3NE031 + AJ3NE032),
                (AJ3NE033 + AJ3NE034 + AJ3NE035 + AJ3NE036), 
                (AJ3NE039 + AJ3NE040 + AJ3NE041 + AJ3NE048 + AJ3NE049 + AJ3NE050 + AJ3NE057 + AJ3NE058 + AJ3NE059), 
                (AJ3NE042 + AJ3NE043 + AJ3NE044 + AJ3NE045 + AJ3NE051 + AJ3NE052 + AJ3NE053  + AJ3NE054 + AJ3NE060 + AJ3NE061 + AJ3NE062 + AJ3NE063))]
    
    target_vars <- c('tract_fips', 'county_fips', 
                     'hh2','hh1', 'hhTOT', 'hh2_black', 'hh1_black', 'hh_blackTOT', 'hh2_white', 'hh1_white', 'hh_whiteTOT', 
                     'hhinc_0_15', 'hhinc_15_20', 'hhinc_20_25', 'hhinc_25_30', 'hhinc_30_35', 'hhinc_35_40', 
                     'hhinc_40_45', 'hhinc_45_50', 'hhinc_50_60', 'hhinc_60_', 'hhincTOT', 
                     'hhinc_sub25_0_15', 'hhinc_sub25_15_20', 'hhinc_sub25_20_25', 'hhinc_sub25_25_30', 
                     'hhinc_sub25_30_35', 'hhinc_sub25_35_40', 'hhinc_sub25_40_45', 'hhinc_sub25_45_50', 
                     'hhinc_sub25_50_60', 'hhinc_sub25_60_', 'hhinc_sub25TOT', 
                     'workers_ft', 'workers_pt', 'pop_rent_share', 'pop_rent_shareD',
                     'renthh_grent_incshare_0_10', 'renthh_grent_incshare_10_15', 'renthh_grent_incshare_15_20', 
                     'renthh_grent_incshare_20_25', 'renthh_grent_incshare_25_30', 'renthh_grent_incshare_30_35', 
                     'renthh_grent_incshare_35_40', 'renthh_grent_incshare_40_50', 'renthh_grent_incshare_50_', 
                     'renthhTOT', 
                     'renthhinc_0_10_sh0_30', 'renthhinc_0_10_sh30_', 'renthhinc_10_20_sh0_30', 
                     'renthhinc_10_20_sh30_', 'renthhinc_20_35_sh0_30', 'renthhinc_20_35_sh30_', 
                     'renthhinc_35_50_sh0_30', 'renthhinc_35_50_sh30_', 'renthhinc_50_sh0_30', 
                     'renthhinc_50_sh30_') 
    
  }
  
  if (x == "ds240_20185_2018_tract.csv") {
    
    data[, c('worker_rent_share', 'worker_rent_shareD') := list(AKAXE003, AKAXE001)]
    
    data[, c('hh_1worker', 
             'hh_2worker', 
             'hh_workerTOT') := 
           list((AKA0E003 + AKA0E002), 
                (AKA0E004 + AKA0E005), 
                (AKA0E001))]
    
    data[, c('hhinc_black_0_15', 
             'hhinc_black_15_20', 
             'hhinc_black_20_25', 
             'hhinc_black_25_30', 
             'hhinc_black_30_35',
             'hhinc_black_35_40', 
             'hhinc_black_40_45',
             'hhinc_black_45_50',
             'hhinc_black_50_60',
             'hhinc_black_60_', 
             'hhinc_blackTOT') :=
           list((AKF1E002 + AKF1E003), 
                (AKF1E004), 
                (AKF1E005),
                (AKF1E006), 
                (AKF1E007), 
                (AKF1E008), 
                (AKF1E009), 
                (AKF1E010), 
                (AKF1E011), 
                (AKF1E012 + AKF1E013 + AKF1E014 + AKF1E015 + AKF1E016 + AKF1E017), 
                (AKF1E001))]
    
    data[, c('hhinc_white_0_15', 
             'hhinc_white_15_20', 
             'hhinc_white_20_25', 
             'hhinc_white_25_30', 
             'hhinc_white_30_35',
             'hhinc_white_35_40', 
             'hhinc_white_40_45',
             'hhinc_white_45_50',
             'hhinc_white_50_60',
             'hhinc_white_60_', 
             'hhinc_whiteTOT') :=
           list((AKF7E002 + AKF7E003), 
                (AKF7E004), 
                (AKF7E005),
                (AKF7E006), 
                (AKF7E007), 
                (AKF7E008), 
                (AKF7E009), 
                (AKF7E010), 
                (AKF7E011), 
                (AKF7E012 + AKF7E013 + AKF7E014 + AKF7E015 + AKF7E016 + AKF7E017), 
                (AKF7E001))]
    
    data[, c('hhinc_sub25_black_0_15', 
             'hhinc_sub25_black_15_20', 
             'hhinc_sub25_black_20_25', 
             'hhinc_sub25_black_25_30', 
             'hhinc_sub25_black_30_35', 
             'hhinc_sub25_black_35_40', 
             'hhinc_sub25_black_40_45', 
             'hhinc_sub25_black_45_50', 
             'hhinc_sub25_black_50_60', 
             'hhinc_sub25_black_60_', 
             'hhinc_sub25_blackTOT') := 
           list((AKGKE003 + AKGKE004), 
                (AKGKE005), 
                (AKGKE006),
                (AKGKE007), 
                (AKGKE008), 
                (AKGKE009), 
                (AKGKE010), 
                (AKGKE011), 
                (AKGKE012), 
                (AKGKE013 + AKGKE014 + AKGKE015 + AKGKE016 + AKGKE017 + AKGKE018), 
                (AKGKE002))]
    
    data[, c('hhinc_sub25_white_0_15', 
             'hhinc_sub25_white_15_20', 
             'hhinc_sub25_white_20_25', 
             'hhinc_sub25_white_25_30', 
             'hhinc_sub25_white_30_35', 
             'hhinc_sub25_white_35_40', 
             'hhinc_sub25_white_40_45', 
             'hhinc_sub25_white_45_50', 
             'hhinc_sub25_white_50_60', 
             'hhinc_sub25_white_60_', 
             'hhinc_sub25_whiteTOT') := 
           list((AKGQE003 + AKGQE004), 
                (AKGQE005), 
                (AKGQE006),
                (AKGQE007), 
                (AKGQE008), 
                (AKGQE009), 
                (AKGQE010), 
                (AKGQE011), 
                (AKGQE012), 
                (AKGQE013 + AKGQE014 + AKGQE015 + AKGQE016 + AKGQE017 + AKGQE018), 
                (AKGQE002))]
    
    data[, c('pinc_ft_0_25', 
             'pinc_ft_25_50', 
             'pinc_ft_50_75', 
             'pinc_ft_75_100', 
             'pinc_ft_100_125', 
             'pinc_ft_125_150', 
             'pinc_ft_150_175', 
             'pinc_ft_175_200', 
             'pinc_ft_200_225', 
             'pinc_ft_225_250', 
             'pinc_ft_250_300', 
             'pinc_ft_TOT', 
             'pinc_pt_0_25', 
             'pinc_pt_25_50', 
             'pinc_pt_50_75', 
             'pinc_pt_75_100', 
             'pinc_pt_100_125', 
             'pinc_pt_125_150', 
             'pinc_pt_TOT') := list((AKH1E006 + AKH1E053), 
                                     (AKH1E007 + AKH1E054), 
                                     (AKH1E008 + AKH1E055), 
                                     (AKH1E009 + AKH1E056), 
                                     (AKH1E010 + AKH1E057), 
                                     (AKH1E011 + AKH1E058), 
                                     (AKH1E012 + AKH1E059), 
                                     (AKH1E013 + AKH1E060), 
                                     (AKH1E014 + AKH1E061), 
                                     (AKH1E015 + AKH1E062), 
                                     (AKH1E016 + AKH1E063), 
                                     (AKH1E003 + AKH1E050), 
                                     (AKH1E029 + AKH1E076), 
                                     (AKH1E030 + AKH1E077), 
                                     (AKH1E031 + AKH1E078), 
                                     (AKH1E032 + AKH1E079),
                                     (AKH1E033 + AKH1E080), 
                                     (AKH1E034 + AKH1E081), 
                                     (AKH1E028 + AKH1E075))]
    
    data[, c('renthh_sub35_single',
             'renthh_sub35_couple', 
             'renthh_hunitsTOT', 
             'renthh_sub35_hunitsTOT',
             'hh_hunitsTOT', 
             'hh_sub35_hunitsTOT',
             'renthh_single_hunitsTOT', 
             'renthh_couple_hunitsTOT', 
             'hh_single_hunitsTOT', 
             'hh_couple_hunitsTOT') := 
           list((AKKIE034 + AKKIE038 + AKKIE043), 
                (AKKIE029 + AKKIE047), 
                (AKKIE026), 
                (AKKIE029 + AKKIE047 + AKKIE034 + AKKIE038 + AKKIE043), 
                (AKKIE001), 
                (AKKIE029 + AKKIE047 + AKKIE034 + AKKIE038 + AKKIE043 + AKKIE005 + AKKIE010 + AKKIE014 + AKKIE019 + AKKIE023), 
                (AKKIE033 + AKKIE037 + AKKIE042), 
                (AKKIE028 + AKKIE046), 
                (AKKIE033 + AKKIE037 + AKKIE042 + AKKIE009 + AKKIE013 + AKKIE018), 
                (AKKIE028 + AKKIE046 + AKKIE004 + AKKIE022))]
    
    data[, c('renthhinc_0_15', 
             'renthhinc_15_20', 
             'renthhinc_20_25', 
             'renthhinc_25_35', 
             'renthhinc_35_50', 
             'renthhinc_50_75',
             'renthhinc_75_',
             'renthhinc_hunitsTOT'
             ) :=
           list((AKLXE015 + AKLXE016 + AKLXE017), 
                (AKLXE018), 
                (AKLXE019),
                (AKLXE020), 
                (AKLXE021), 
                (AKLXE022), 
                (AKLXE023 + AKLXE024 +AKLXE025), 
                (AKLXE014))]
    
    target_vars <- c('tract_fips', 'county_fips', 
                     'worker_rent_share', 'worker_rent_shareD',
                     'hh_1worker', 'hh_2worker', 'hh_workerTOT', 
                     'hhinc_black_0_15', 'hhinc_black_15_20', 'hhinc_black_20_25', 
                     'hhinc_black_25_30', 'hhinc_black_30_35', 'hhinc_black_35_40', 
                     'hhinc_black_40_45', 'hhinc_black_45_50', 'hhinc_black_50_60',
                     'hhinc_black_60_', 'hhinc_blackTOT', 
                     'hhinc_white_0_15', 'hhinc_white_15_20', 'hhinc_white_20_25', 
                     'hhinc_white_25_30', 'hhinc_white_30_35', 'hhinc_white_35_40', 
                     'hhinc_white_40_45', 'hhinc_white_45_50', 'hhinc_white_50_60',
                     'hhinc_white_60_', 'hhinc_whiteTOT', 
                     'hhinc_sub25_black_0_15', 'hhinc_sub25_black_15_20', 'hhinc_sub25_black_20_25', 
                     'hhinc_sub25_black_25_30', 'hhinc_sub25_black_30_35', 'hhinc_sub25_black_35_40', 
                     'hhinc_sub25_black_40_45', 'hhinc_sub25_black_45_50', 'hhinc_sub25_black_50_60', 
                     'hhinc_sub25_black_60_', 'hhinc_sub25_blackTOT', 
                     'hhinc_sub25_white_0_15', 'hhinc_sub25_white_15_20', 'hhinc_sub25_white_20_25', 
                     'hhinc_sub25_white_25_30', 'hhinc_sub25_white_30_35', 'hhinc_sub25_white_35_40', 
                     'hhinc_sub25_white_40_45', 'hhinc_sub25_white_45_50', 'hhinc_sub25_white_50_60', 
                     'hhinc_sub25_white_60_', 'hhinc_sub25_whiteTOT', 
                     'pinc_ft_0_25', 'pinc_ft_25_50', 'pinc_ft_50_75', 'pinc_ft_75_100', 'pinc_ft_100_125', 
                     'pinc_ft_125_150', 'pinc_ft_150_175', 'pinc_ft_175_200', 'pinc_ft_200_225', 
                     'pinc_ft_225_250', 'pinc_ft_250_300', 'pinc_ft_TOT', 'pinc_pt_0_25', 
                     'pinc_pt_25_50', 'pinc_pt_50_75', 'pinc_pt_75_100', 'pinc_pt_100_125', 
                     'pinc_pt_125_150', 'pinc_pt_TOT',
                     'renthh_sub35_single', 'renthh_sub35_couple', 'renthh_hunitsTOT', 
                     'renthh_sub35_hunitsTOT', 'hh_hunitsTOT', 'hh_sub35_hunitsTOT',
                     'renthh_single_hunitsTOT', 'renthh_couple_hunitsTOT', 'hh_single_hunitsTOT', 
                     'hh_couple_hunitsTOT', 
                     'renthhinc_0_15', 'renthhinc_15_20', 'renthhinc_20_25', 'renthhinc_25_35', 
                     'renthhinc_35_50', 'renthhinc_50_75', 'renthhinc_75_', 'renthhinc_hunitsTOT')
  }
  
  data <- data[, ..target_vars]
  
  return(data)
  
}

main()