remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")

load_packages(c('tidyverse', 'data.table', 'matrixStats', 'knitr', 'tigris', 'sf', 'sfheaders', 'remotes', 'choroplethrZip',
                'kableExtra', 'ggplot2', 'png', 'readxl', 'readstata13', 'unikn', 'RColorBrewer', 'viridis', 'maps'))

theme_set(theme_minimal())
options(scipen=999)

main <- function() {
  datadir <- "../../../drive/derived_large/output/"
  outdir <- "../output/"
  tempdir <- "../temp/"
  
  options(tigris_class = "sf")
  
  remotes::install_github("jrnold/stataXml") #need this to process stata dates
  library('stataXml')
  
  df <- read.dta13(paste0(datadir, 'unbal_rent_panel.dta'))
  df <- setDT(df)
  df[, countyfips := str_pad(as.character(countyfips), 5, pad = 0)]
  df[, zipcode := str_pad(as.character(zipcode), 5, pad = 0)]
  df[, year_month := fromStataTime(year_month, '%tm')]
  
  zip_zcta_xwalk <- setDT(read_excel('../../../raw/crosswalk/zip_to_zcta_2019.xlsx'))
  zip_zcta_xwalk <- zip_zcta_xwalk[!str_detect(zip_zcta_xwalk$ZIP_TYPE, "^Post")]
  setnames(zip_zcta_xwalk, old = c('ZIP_CODE', 'ZCTA'), new = c('zipcode', 'zcta'))
  
  zcta_place_xwalk <- fread('../../../raw/crosswalk/zcta_place_xwalk.csv', 
                            select = c('zcta5', 'placefp', 'placenm', 'afact'))
  setnames(zcta_place_xwalk, old = c('zcta5', 'placefp'), new  = c('zcta', 'place_code'))
  zcta_place_xwalk[, 'zcta' := str_pad(zcta, 5, pad = 0)]
  
  zip_county <- setDT(read_excel('../../../raw/crosswalk/ZIP_COUNTY_122019.xlsx', 
                               col_types = c('text', 'text', 'numeric', 'numeric', 'numeric', 'numeric')))
  zip_county <- zip_county[, c('ZIP', "COUNTY", 'TOT_RATIO')]
  setnames(zip_county, old = c('ZIP', 'COUNTY'), new = c('zipcode', 'county'))
  
  test <- zctas(starts_with = '029')
  
  plot_sample <- function(df_data, 
                          zipzcta = zip_zcta_xwalk, 
                          out = outdir) {
    
    #removing alaska and hawaii for visual clarity (we have though 26 zipcodes there)
    sample_zip <- df_data[!is.na(medrentpricepsqft_sfcc) & statefips!=15 & statefips!=2, first(.SD), by = zipcode][, .(zipcode)]
    sample_zcta <- zipzcta[sample_zip, on = .(zipcode)][, .(zcta)][, value := 1]
    setnames(sample_zcta, old = 'zcta', new = 'region')
    
    data(zip.map)
    zcta_map <- sfheaders::sf_polygon(zip.map, x = 'long', y = 'lat', polygon_id = 'id', keep = T)
    zcta_sample_map <- inner_join(zcta_map, sample_zcta, on = 'region')
    
    us_boundary <- map_data('state')
    us_boundary <- sfheaders::sf_multipolygon(map_data('state'), x = 'long', y = 'lat', multipolygon_id = 'group')
    
    plot<- ggplot(us_boundary) + 
      geom_sf(fill= NA) + 
      theme_void() + 
      geom_sf(data = zcta_sample_map, color = 'transparent', fill = '#035F72') + 
      theme(aspect.ratio = 0.6)  
    return(plot)
  }
  
  png(filename = paste0(outdir, 'sample_map.png'), width = 7680, height = 7680)
  plot_sample(df)
  dev.off()
  
  
  plot_changes_msa <- function(stateabb, city, target_msa, 
                           plotname, df_data, nmon, mwdate,
                           zipcounty = zip_county, 
                           zipzcta = zip_zcta_xwalk,
                           zctaplace = zcta_place_xwalk,
                           out = outdir) {
    #identify main variable to plot: % change in rents after last MW change
    df_target <- df_data[msa %like% target_msa, 
                          c('zipcode', 'countyfips', 'year_month', 'msa', 'place_code',
                            'medrentpricepsqft_sfcc', 'actual_mw', 'dactual_mw', 
                            'exp_mw_totjob')]
    df_target <- df_target[, Fyear_month := shift(year_month, type = 'lead'), by = zipcode]
    df_target <- df_target[Fyear_month >= as.Date(mwdate), ]
    
    nmonths <- nmon
    nmonths2 <- nmonths + 1 # keep t-1 for computing percentage change
    df_target <- df_target[df_target[, .I[1:nmonths2], zipcode]$V1]
    df_target[, pct_rentch := (medrentpricepsqft_sfcc[.N] - medrentpricepsqft_sfcc[1])/medrentpricepsqft_sfcc[1], by = 'zipcode']
    df_target <- df_target[, last(.SD), by = zipcode]
    df_target[, 'region' := zipcode]
    
    counties <- unique(df_target$countyfips)
    #select all zips via county
    zip_county_target <- zipcounty[county %in% counties, ]
    zip_county_target <- zip_county_target[zip_county_target[, .I[which.max(TOT_RATIO)], by=zipcode]$V1] #zip in county with larger share in
    
    #select zcta via zipcodes
    zip_zcta_target <- zip_county_target[zipzcta, on = 'zipcode', nomatch = 0]
    zip_zcta_target <- df_target[, c('zipcode', 'pct_rentch')][zip_zcta_target, on = 'zipcode']
    setorderv(zip_zcta_target, c('zcta', 'pct_rentch'))
    zip_zcta_target <- zip_zcta_target[zip_zcta_target[, .I[1], by = zcta][['V1']]]
    
    #download state zcta level maps
    #sdf <- tigris::zctas(state = stateabb, cb = "T")  # download zcta level maps for state
    #setnames(sdf, old = c('ZCTA5CE10'), new = c('zcta'))
    #sdf <- inner_join(sdf, zip_zcta_target, by = 'zcta') #append and filter values for NYC zctas to spatial df
    #sdf_city <- left_join(sdf, zctaplace, by = 'zcta')
    #sdf_city <- subset(sdf_city, place_code == city)
    
    data(zip.map)
    zcta_map <- sfheaders::sf_polygon(zip.map, x = 'long', y = 'lat', polygon_id = 'id', keep = T)
    zcta_sample_map <- inner_join(zcta_map, df_target, on = 'region')
    zcta_city <- zcta_sample_map[zcta_sample_map$place_code == city, ]
    zcta_city <- st_union(zcta_city)
    zcta_boundary <- st_union(zcta_sample_map)
    
    
    #define color quintiles breaks
    nq <- 6
    b <- quantile(zcta_sample_map$pct_rentch, probs = seq(0,1, length.out = (nq + 1)), na.rm = T)
    labels <- c()
    for (idx in 1:length(b)){
      labels <- c(labels, paste0('(',round(b[idx]*100, 0), ', ', round(b[idx+1]*100, 0), ')'))
    }
    labels <- labels[1:length(labels)-1]
    
    pal <- seecol(c(pal_petrol), n =nq, hex = T)
    pal <- unname(pal)
      
    zcta_sample_map$pct_rentch_qtl <- cut(zcta_sample_map$pct_rentch, 
                                          breaks = b, 
                                          labels = labels, 
                                          include.lowest = T)

    plot <- ggplot(zcta_sample_map) + 
      geom_sf(aes(fill=pct_rentch_qtl), color="white") +
      geom_sf(data = zcta_boundary, color = 'dimgrey', fill = 'transparent') +  
      geom_sf(data = zcta_city, color = 'darkred', fill = 'transparent', size = 10) +
      theme_void() +
      theme(panel.grid.major = element_line(colour = 'transparent')) +
      scale_color_manual(
        values = pal,
        name = "Rent Change (%)", 
        aesthetics = 'fill',
        guide = guide_legend(
          direction = "horizontal",
          keyheight = unit(2, units = "cm"),
          keywidth = unit(70 / length(labels), units = "cm"),
          title.position = 'top',
          # I shift the labels around, the should be placed 
          # exactly at the right end of each legend key
          title.hjust = 0.5,
          label.hjust = 1,
          nrow = 1,
          byrow = T,
          # also the guide needs to be reversed
          reverse = F,
          label.position = "bottom"
        ), na.value = 'gray') +
      labs(title=plotname, subtitle = paste0('MW change date: ', mwdate)) + 
      theme(legend.position = "bottom", 
            plot.title = element_text(size=180),
            plot.subtitle = element_text(size = 140), 
            legend.title = element_text(size = 120), 
            legend.text = element_text(size = 80))
    #dev.off()   
    return(plot)
  }
  

# L.A. MSA
la_counties <- c('06037', '06059')
png(filename = paste0(outdir, 'rentch_pct_LAmsa.png'), width = 960, height = 960)
plot_changes(counties = la_counties, stateabb = 'CA', nmon = 6, plotname = "L.A. MSA", df_data = df, city = 44000)
dev.off()

# Seattle MSA
sea_counties <- c('53033', '53053', '53061')
png(filename = paste0(outdir, 'rentch_pct_SEATTLEmsa.png'), width = 960, height = 960)
plot_changes(
             target_msa = "Seattle",
             stateabb = 'WA', 
             nmon = 6, 
             plotname = "Seattle MSA", 
             df_data = df, 
             city = 63000, 
             mwdate = '2019-01-01')
dev.off()

# Chicago MSA
chi_counties <- c('17031')
  png(filename = paste0(outdir, 'rentch_pct_CHICAGOcity.png'), width = 960, height = 960)
plot_changes(counties = chi_counties, stateabb = 'IL', nmon = 6, plotname = "Chicago city", df_data = df)
dev.off()

# SF msa 
sf_counties <- c('06001', '06013', '06075', '06081', '06041')
png(filename = paste0(outdir, 'rentch_pct_SFmsa.png'), width = 960, height = 960)
plot_changes(counties = sf_counties, 
             stateabb = 'CA', 
             nmon = 6, 
             plotname = "SF MSA", 
             df_data = df, 
             mwdate = '2019-01-01')
dev.off()
#San DIego
png(filename = paste0(outdir, 'San_DiegoMSA.png'), width = 7680, height = 7680)
plot_changes_msa(stateabb = 'CA',
             target_msa = "San Diego", 
             city = 66000, 
             nmon = 6, 
             plotname = "San Diego MSA", 
             df_data = df, 
             mwdate = '2019-01-01')
dev.off()

#Houston MSA
ho_counties <- c('48201', '48157', '48339', '48039', '48167', '48291', '48473', '48071', '48015', '48407')
png(filename = paste0(outdir, 'rentch_pct_HOmsa.png'), width = 960, height = 960)
plot_changes(counties = ho_counties, stateabb = 'TX', nmon = 6, plotname = "HOUSTON MSA", df_data = df)
dev.off()

#Miami MSA
mia_counties <- c('12086', '12011', '12099')
png(filename = paste0(outdir, 'rentch_pct_MIAmsa.png'), width = 960, height = 960)
plot_changes(counties = mia_counties, stateabb = 'FL', nmon = 6, plotname = "MIAMI MSA", df_data = df)
dev.off()
}





