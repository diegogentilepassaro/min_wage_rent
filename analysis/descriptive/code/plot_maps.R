remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")

load_packages(c('tidyverse', 'data.table', 'matrixStats', 'knitr', 'tigris', 'sf', 'sfheaders', 'remotes', 'choroplethrZip',
                'kableExtra', 'ggplot2', 'png', 'readxl', 'readstata13', 'unikn', 'RColorBrewer', 'viridis', 'maps', 'stringr'))

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
  
  
  plot_changes_city <- function(target_counties, mwarea, target_msa, 
                           plotname, df_data, nmon, mwdate,
                           zipcounty = zip_county, 
                           zipzcta = zip_zcta_xwalk,
                           zctaplace = zcta_place_xwalk,
                           out = outdir) {
    nmonths <- nmon
    nmonths2 <- nmonths + 1 # keep t-1 for computing percentage change
    
    #identify main variable to plot: % change in rents after last MW change
    df_target <- df_data[msa %like% target_msa, 
                         c('zipcode', 'countyfips', 'year_month', 'msa', 'place_code',
                           'medrentpricepsqft_sfcc', 'actual_mw', 'dactual_mw', 
                           'exp_mw_totjob')]
    df_target <- df_target[, Fyear_month := shift(year_month, type = 'lead'), by = zipcode]
    df_target <- df_target[Fyear_month >= as.Date(mwdate), ]
    df_target <- df_target[df_target[, .I[1:nmonths2], zipcode]$V1]
    df_target[, pct_rentch := (medrentpricepsqft_sfcc[.N] - medrentpricepsqft_sfcc[1])/medrentpricepsqft_sfcc[1], by = 'zipcode']
    df_target <- df_target[, last(.SD), by = zipcode]
    df_target <- df_target[!is.na(pct_rentch),]
    df_target[, 'region' := zipcode]
    
    data(zip.map)
    zcta_map <- sfheaders::sf_multipolygon(zip.map, x = 'long', y = 'lat', multipolygon_id = 'id', polygon_id = 'piece', keep = T)
    zcta_sample_map <- inner_join(zcta_map, df_target, on = 'region')
    
    #select all counties for baseline map
    #zip_county_target <- zipcounty[county %in% target_counties, ]
    #zip_county_target <- zip_county_target[zip_county_target[, .I[which.max(TOT_RATIO)], by=zipcode]$V1] #zip in county with larger share in
    #zcta_county_target <- zip_county_target[zipzcta[, .(zipcode, zcta)], on = 'zipcode', nomatch = 0]
    #zcta_county_target <- zcta_county_target[!duplicated(zcta_county_target[, .(zcta, county)]), .(zcta, county)]
    #zcta_base_map <- inner_join(zcta_map, zcta_county_target, by = c('region' = 'zcta'))
    
    county_fips <- fips_codes
    county_fips <- setDT(county_fips)
    county_fips <- county_fips[, 'countyfips' := paste0(state_code, county_code)][, .(countyfips, county, state_name)]
    setnames(county_fips, old = c('county', 'state_name'), new = c('subregion', 'region'))
    county_map <- map_data('county')
    county_map <- setDT(county_map)
    county_map <- county_map[, c('region', 'subregion') := .(str_to_title(region), str_to_title(paste0(subregion, ' county')))]
    county_map <- left_join(county_map, county_fips, by = c('region', 'subregion'))
    county_map <- county_map[countyfips %in% target_counties, ]
    base_map <- sfheaders::sf_polygon(county_map, x = 'long', y = 'lat', polygon_id = 'countyfips')
    
    zcta_cty <- zcta_sample_map[zcta_sample_map$place_code == mwarea, ]
    zcta_cty <- st_union(zcta_cty)
    
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
    
    plot<- ggplot() + 
      geom_sf(data = base_map, color = 'black', fill = 'transparent', size = 1.5) +  
      geom_sf(data = zcta_sample_map, aes(fill=pct_rentch_qtl), color="white") +
      geom_sf(data = zcta_cty, color = 'darkred', fill = 'transparent', size = 5) +
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
  
  plot_changes_chicago <- function(target_counties, mwarea, target_msa,
                                plotname, df_data, nmon, mwdate,
                                zipcounty = zip_county, 
                                zipzcta = zip_zcta_xwalk,
                                zctaplace = zcta_place_xwalk,
                                out = outdir) {
    nmonths <- nmon
    nmonths2 <- nmonths + 1 # keep t-1 for computing percentage change
    
    #identify main variable to plot: % change in rents after last MW change
    df_target <- df_data[msa %like% target_msa, 
                         c('zipcode', 'countyfips', 'year_month', 'msa', 'place_code',
                           'medrentpricepsqft_sfcc', 'actual_mw', 'dactual_mw', 
                           'exp_mw_totjob')]
    df_target <- df_target[, Fyear_month := shift(year_month, type = 'lead'), by = zipcode]
    df_target <- df_target[Fyear_month >= as.Date(mwdate), ]
    df_target <- df_target[df_target[, .I[1:nmonths2], zipcode]$V1]
    df_target[, pct_rentch := (medrentpricepsqft_sfcc[.N] - medrentpricepsqft_sfcc[1])/medrentpricepsqft_sfcc[1], by = 'zipcode']
    df_target <- df_target[, last(.SD), by = zipcode]
    df_target <- df_target[!is.na(pct_rentch),]
    df_target[, 'region' := zipcode]
    
    #counties <- unique(df_target$countyfips)
    #counties <- counties[!is.na(counties)]
   
     #select all counties for baseline map
    zip_county_target <- zipcounty[county %in% target_counties, ]
    zip_county_target <- zip_county_target[zip_county_target[, .I[which.max(TOT_RATIO)], by=zipcode]$V1] #zip in county with larger share in
    zcta_county_target <- zip_county_target[zipzcta[, .(zipcode, zcta)], on = 'zipcode', nomatch = 0]
    zcta_county_target <- zcta_county_target[!duplicated(zcta_county_target[, .(zcta, county)]), .(zcta, county)]
    
    data(zip.map)
    zcta_map <- sfheaders::sf_multipolygon(zip.map, x = 'long', y = 'lat', multipolygon_id = 'id', polygon_id = 'piece', keep = T)
    zcta_sample_map <- inner_join(zcta_map, df_target, on = 'region')
    
    zcta_base_map <- inner_join(zcta_map, zcta_county_target, by = c('region' = 'zcta'))
    
    zcta_cty <- zcta_base_map[zcta_base_map$county == mwarea, ]
    zcta_cty <- st_union(zcta_cty)

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
    
    plot<- ggplot() + 
      geom_sf(data = zcta_base_map, color = 'black', fill = 'transparent', size = 1.5) +  
      geom_sf(data = zcta_sample_map, aes(fill=pct_rentch_qtl), color="white") +
      geom_sf(data = zcta_cty, color = 'darkred', fill = 'transparent', size = 5) +
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
png(filename = paste0(outdir, 'LAmsa.png'), width = 7680, height = 7680)
plot_changes_city(stateabb = 'CA',
                  target_msa = "Los Angeles",
                  nmon = 6, 
                  plotname = "Los Angeles MSA", 
                  df_data = df, 
                  city = 44000, 
                  mwdate = '2019-07-01')
dev.off()

#Berkeley, CA 
png(filename = paste0(outdir, 'Berkeley.png'), width = 7680, height = 7680)
plot_changes_city(stateabb = 'CA',
                  target_msa = "Berkeley",
                  nmon = 6, 
                  plotname = "SF-Oakland-Berkeley MSA", 
                  df_data = df, 
                  city = 6000, 
                  mwdate = '2019-07-01')
dev.off()

# Seattle MSA
sea_counties <- c('53033', '53053', '53061')
png(filename = paste0(outdir, 'Seattle_msa.png'), width = 960, height = 960)
plot_changes_city(target_counties = sea_counties,
             target_msa = "Seattle",
             nmon = 6, 
             plotname = "Seattle MSA", 
             df_data = df, 
             mwarea = 63000, 
             mwdate = '2019-01-01')
dev.off()

# Chicago MSA (cook county increase MW in July 2019)
chi_counties <- c('17031', '17037', '17043', '17063', '17091', '17089', '17903', '17111', '17197')
png(filename = paste0(outdir, 'CHICAGO_msa.png'), width = 7680, height = 7680)
plot_changes_chicago(target_counties = chi_counties,
             target_msa = "Chicago",
             mwarea = '17031',
             nmon = 6, 
             plotname = "Chicago MSA", 
             df_data = df, 
             mwdate = '2019-07-01')
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
#San Diego
png(filename = paste0(outdir, 'San_DiegoMSA.png'), width = 7680, height = 7680)
plot_changes_city(stateabb = 'CA',
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





