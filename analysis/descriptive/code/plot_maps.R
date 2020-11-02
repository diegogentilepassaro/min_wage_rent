remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")

load_packages(c('tidyverse', 'tigris', 'data.table', 'matrixStats', 'knitr', 'sf', 
                'kableExtra', 'ggplot2', 'png', 'readxl', 'readstata13', 'unikn', 'RColorBrewer', 'viridis'))

theme_set(theme_minimal())
options(scipen=999)

main <- function() {
  datadir <- "../../../drive/derived_large/output/"
  outdir <- "../output/"
  tempdir <- "../temp/"
  
  options(tigris_class = "sf")
  
  df <- read.dta13(paste0(datadir, 'unbal_rent_panel.dta'))
  df <- setDT(df)
  df[, countyfips := str_pad(as.character(countyfips), 5, pad = 0)]
  df[, zipcode := str_pad(as.character(zipcode), 5, pad = 0)]
  
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
  
  plot_changes <- function(counties, stateabb, nmon, 
                           plotname, df_data, city,
                           zipcounty = zip_county, 
                           zipzcta = zip_zcta_xwalk,
                           zctaplace = zcta_place_xwalk,
                           out = outdir) {
    #identify main variable to plot: % change in rents after last MW change
    df_target <- df_data[countyfips %in% counties, 
                         c('zipcode', 'countyfips', 'year_month', 'msa', 'place_code',
                           'medrentpricepsqft_sfcc', 'actual_mw', 'dactual_mw', 
                           'exp_mw_totjob')]
    #identify last mw change with at least 12 months of rents after
    df_target <- df_target[df_target[, .I[.N], by = zipcode][['V1']], dactual_mw := 0] #replace last Mw change in sample with 0 'cause it has no following month
    df_target[, F.dactual_mw := shift(dactual_mw, type = 'lead'), by = zipcode]
    df_target[F.dactual_mw==0, F.dactual_mw:=NA] # replace 0 MW change with missing
    df_target[, last_date := tail(year_month[!is.na(F.dactual_mw)],1), by = 'zipcode'] # get the date for the last non-missing MW change
    df_target <- df_target[year_month>=last_date,]
    
    nmonths <- nmon
    nmonths2 <- nmonths + 1 # keep t-1 for computing percentage change
    df_target <- df_target[df_target[, .I[1:nmonths2], zipcode]$V1]
    df_target[, pct_rentch := (medrentpricepsqft_sfcc[.N] - medrentpricepsqft_sfcc[1])/medrentpricepsqft_sfcc[1], by = 'zipcode']
    df_target <- df_target[year_month==(last_date+ 1),]
    
    
    #select all zips via county
    zip_county_target <- zipcounty[county %in% counties, ]
    zip_county_target <- zip_county_target[zip_county_target[, .I[which.max(TOT_RATIO)], by=zipcode]$V1] #zip in county with larger share in
    
    #select zcta via zipcodes
    zip_zcta_target <- zip_county_target[zipzcta, on = 'zipcode', nomatch = 0]
    zip_zcta_target <- df_target[, c('zipcode', 'pct_rentch')][zip_zcta_target, on = 'zipcode']
    setorderv(zip_zcta_target, c('zcta', 'pct_rentch'))
    zip_zcta_target <- zip_zcta_target[zip_zcta_target[, .I[1], by = zcta][['V1']]]
    
    #download state zcta level maps
    sdf <- zctas(state = stateabb, cb = "T")  # download zcta level maps for state
    setnames(sdf, old = c('ZCTA5CE10'), new = c('zcta'))
    sdf <- inner_join(sdf, zip_zcta_target, by = 'zcta') #append and filter values for NYC zctas to spatial df
    sdf_city <- left_join(sdf, zctaplace, by = 'zcta')
    sdf_city <- subset(sdf_city, place_code == city)
    
    #define color quintiles breaks
    b <- quantile(sdf$pct_rentch, probs = seq(0,1, length.out = 6), na.rm = T)
    labels <- c()
    for (idx in 1:length(b)){
      labels <- c(labels, paste0(round(b[idx]*100, 0), ' - ', round(b[idx+1]*100, 0)))
    }
    labels <- labels[1:length(labels)-1]
    
    pal <- usecol(pal = pal_seegruen, n = 20)
    pal <- pal[c(T,F, F, F)]
      
    sdf$pct_rentch_qtl <- cut(sdf$pct_rentch, breaks = b, labels = labels, include.lowest = T)
    #png(filename = paste0(out, 'rentch_pct_', plotname, ".png"), width = 960, height = 960)
    #png(filename = paste0(out, "trialNY.png"), width = 960, height = 960)
    plot <- ggplot(sdf) + 
      geom_sf(aes(fill=pct_rentch), color="white") +
      theme_void() +
      theme(panel.grid.major = element_line(colour = 'transparent')) +
      scale_fill_distiller(palette="RdYlBu", direction=1, name="Rent Change (%)", type = "div") +
      labs(title=plotname)
    
    
    ggplot(sdf) + 
      geom_sf(aes(fill=pct_rentch_qtl), color="white") +
      geom_sf(data = sdf_city, color = 'orangered', fill = 'transparent') +
      theme_void() +
      theme(panel.grid.major = element_line(colour = 'transparent')) +
      scale_color_manual(
        values = pal,
        name = "Rent Change (%)", 
        aesthetics = 'fill',
        guide = guide_legend(
          direction = "horizontal",
          keyheight = unit(2, units = "mm"),
          keywidth = unit(70 / length(labels), units = "mm"),
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
        ), na.value = 'azure2') +
      labs(title=plotname) + 
      theme(legend.position = "bottom")
    #dev.off()   
    return(plot)
  }
  
# New York city
nyc_counties <- c('36005', '36047', '36061', '36081', '36085')  
plot_changes(counties = nyc_counties, stateabb = 'NY', nmon = 6, plotname = "NewYorkCity", df_data = df)

# L.A. MSA
la_counties <- c('06037', '06059')
png(filename = paste0(outdir, 'rentch_pct_LAmsa.png'), width = 960, height = 960)
plot_changes(counties = la_counties, stateabb = 'CA', nmon = 6, plotname = "L.A. MSA", df_data = df)
dev.off()

# Seattle MSA
sea_counties <- c('53033', '53053', '53061')
png(filename = paste0(outdir, 'rentch_pct_SEATTLEmsa.png'), width = 960, height = 960)
plot_changes(counties = sea_counties, stateabb = 'WA', nmon = 6, plotname = "Seattle MSA", df_data = df, city = 63000)
dev.off()

# Chicago MSA
chi_counties <- c('17031')
  png(filename = paste0(outdir, 'rentch_pct_CHICAGOcity.png'), width = 960, height = 960)
plot_changes(counties = chi_counties, stateabb = 'IL', nmon = 6, plotname = "Chicago city", df_data = df)
dev.off()

# SF msa 
sf_counties <- c('06001', '06013', '06075', '06081', '06041')
png(filename = paste0(outdir, 'rentch_pct_SFmsa.png'), width = 960, height = 960)
plot_changes(counties = sf_counties, stateabb = 'CA', nmon = 6, plotname = "SF MSA", df_data = df)
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


test <- df[countyfips %in% sea_counties, ]




