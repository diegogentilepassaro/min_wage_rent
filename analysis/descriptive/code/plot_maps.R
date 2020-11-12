remove(list = ls())
source("../../../lib/R/load_packages.R")
source("../../../lib/R/save_data.R")

load_packages(c('tidyverse', 'DescTools', 'data.table', 'matrixStats', 'knitr', 'tigris', 'sf', 'sfheaders', 'remotes', 'choroplethrZip',
                'kableExtra', 'ggplot2', 'png', 'readxl', 'readstata13', 'unikn', 'RColorBrewer', 'maps', 'stringr', 'tidycensus'))

theme_set(theme_minimal())
options(scipen=999)


datadir <- "../../../drive/derived_large/output/"
outdir <- "../output/"
tempdir <- "../temp/"

options(tigris_class = "sf")

remotes::install_github("jrnold/stataXml") #need this to process stata dates
library('stataXml')
  

make_xwalks <- function() {
  zip_zcta_xwalk <- setDT(read_excel('../../../raw/crosswalk/zip_to_zcta_2019.xlsx'))
  zip_zcta_xwalk <- zip_zcta_xwalk[!str_detect(zip_zcta_xwalk$ZIP_TYPE, "^Post")]
  setnames(zip_zcta_xwalk, old = c('ZIP_CODE', 'ZCTA'), new = c('zipcode', 'zcta'))
  
  zcta_place_xwalk <- fread('../../../raw/crosswalk/zcta_place_xwalk.csv', 
                            select = c('zcta5', 'placefp', 'placenm', 'afact'))
  setnames(zcta_place_xwalk, old = c('zcta5', 'placefp'), new  = c('zcta', 'place_code'))
  zcta_place_xwalk[, 'zcta' := str_pad(zcta, 5, pad = 0)]
  zcta_place_xwalk <- zcta_place_xwalk[zcta_place_xwalk[, .I[which.max(afact)], by = 'zcta']$V1]
  
  zcta_msa_xwalk <- fread('../../../raw/crosswalk/zcta_cbsa_xwalk.csv', 
                          drop = c('zipname', 'pop10'))
  setnames(zcta_msa_xwalk, old = c('zcta5', 'cbsa10', 'cbsaname10'), new = c('zcta', 'msa', 'msaname'))
  zcta_msa_xwalk[, 'zcta' := str_pad(zcta, 5, pad = 0)]
  zcta_msa_xwalk <- zcta_msa_xwalk[zcta_msa_xwalk[, .I[which.max(afact)], by = 'zcta']$V1]
  
  zip_county <- setDT(read_excel('../../../raw/crosswalk/ZIP_COUNTY_122019.xlsx', 
                                 col_types = c('text', 'text', 'numeric', 'numeric', 'numeric', 'numeric')))
  zip_county <- zip_county[, c('ZIP', "COUNTY", 'TOT_RATIO')]
  setnames(zip_county, old = c('ZIP', 'COUNTY'), new = c('zipcode', 'county'))
  zip_county  <- zip_county[zip_county[, .I[which.max(TOT_RATIO)], by = 'zipcode']$V1]
  
  return(list('zip_zcta_xwalk' = zip_zcta_xwalk, 'zcta_place_xwalk' = zcta_place_xwalk, 'zcta_msa_xwalk' = zcta_msa_xwalk, 'zip_county' = zip_county))
}

plot_sample <- function(df_data, 
                        zipzcta,
                        zctamsa,
                        plotmsa = F,
                        out) {
  
  #removing alaska and hawaii for visual clarity (we have though 26 zipcodes there)
  sample_zip <- df_data[!is.na(medrentpricepsqft_sfcc) & statefips!=15 & statefips!=2, first(.SD), by = zipcode][, .(zipcode)]
  sample_zcta <- zipzcta[sample_zip, on = .(zipcode)][, .(zcta)][, value := 1]
  setnames(sample_zcta, old = 'zcta', new = 'region')
  
  data(zip.map)
  zcta_map <- sfheaders::sf_multipolygon(zip.map, x = 'long', y = 'lat', multipolygon_id = 'id', polygon_id = 'piece', keep = T)
  zcta_sample_map <- inner_join(zcta_map, sample_zcta, on = 'region')
  zcta_sample_map <- mutate(zcta_sample_map, fillvar = 2)
  st_crs(zcta_sample_map) <-4326
  
  msa_map <- left_join(zcta_map, zctamsa, by = c('region' = 'zcta')) %>%
    filter(msaname!='99999') %>%
    filter(stab!='AK' & stab!='HI') %>%
    group_by(msa) %>%
    summarise(geometry = st_union(geometry)) %>%
    mutate(fillvar = 1)
  st_crs(msa_map) <- 4326
  
  us_boundary <- map_data('state')
  us_boundary <- sfheaders::sf_multipolygon(map_data('state'), x = 'long', y = 'lat', multipolygon_id = 'group')
  st_crs(us_boundary) <-4326
  
  if (plotmsa == T) {
    plot<- ggplot() + 
      geom_sf(data = msa_map, color = 'transparent', aes(fill = 'msafill')) +
      geom_sf(data = zcta_sample_map, color = 'transparent', aes(fill = 'samplefill')) + 
      geom_sf(data = us_boundary, fill= NA, size = 1.5) +
      theme_void() + 
      theme(aspect.ratio = 0.6) + 
      scale_fill_manual(values = c('msafill' = unname(seecol(pal_seeblau, hex = T)[1]),'samplefill' = unname(seecol(pal_petrol, hex = T)[5])), 
                         label = c('CBSAs', 'Sample'), 
                         name = '', 
                         guide = guide_legend(direction = "horizontal",
                                              keyheight = unit(4, units = "cm"),
                                              keywidth = unit(8, units = "cm"),
                                              byrow = T)) + 
      theme(legend.position = "bottom", 
            plot.title = element_text(size=180),
            plot.subtitle = element_text(size = 140), 
            legend.text = element_text(size = 80))
  } else if (plotmsa==F) {
      plot<- ggplot() + 
        geom_sf(data = zcta_sample_map, color = 'transparent', aes(fill = 'samplefill')) + 
        geom_sf(data = us_boundary, fill= NA, size = 1.5) +
        theme_void() + 
        theme(aspect.ratio = 0.6) + 
        scale_fill_manual(values = c('samplefill' = unname(seecol(pal_petrol, hex = T)[5])), 
                          label = c('Zillow Sample'), 
                          name = '', 
                          guide = guide_legend(direction = "horizontal",
                                               keyheight = unit(4, units = "cm"),
                                               keywidth = unit(8, units = "cm"),
                                               byrow = T)) + 
        theme(legend.position = "bottom", 
              plot.title = element_text(size=180),
              plot.subtitle = element_text(size = 140), 
              legend.text = element_text(size = 80))
  }
  return(plot)
}
plot_demo <- function(target_demo,
                      legend_name,
                      zctamsa, 
                      out) {
  census_api_key('6e4bf831630a20872606ce3949acd975473a1d87')
  #censusvar <- load_variables(year = 2010, dataset = 'sf1') #to navigate census variables
  census_target <- c(pop = 'P001001', urbpop = 'P002002', housing_units = 'H001001', house_urban = 'H002002')
  df_census <- get_decennial(geography = 'zcta', year = 2010, state = NULL, geometry = F,
                             variables = census_target, output = 'wide') %>%
    rename('zcta' = 'GEOID') %>%
    select(- 'NAME') %>%
    setDT()
  
  data(zip.map)
  zcta_map <- sfheaders::sf_multipolygon(zip.map, x = 'long', y = 'lat', multipolygon_id = 'id', polygon_id = 'piece', keep = T) %>%
    select(- 'id', - 'order', -'group', -'AFFGEOID10', -'ZCTA5CE10', -'GEOID10', -'hole') %>%
    rename('zcta' = 'region') %>%
    left_join(zctamsa, by = 'zcta') %>%
    left_join(df_census, by = 'zcta') %>%
    mutate('ALAND10' = ALAND10 * 0.00000038610) %>% #convrt to square miles
    mutate(popden      = Winsorize(pop / ALAND10), 
           urbpopden   = Winsorize(urbpop / ALAND10), 
           houseden    = Winsorize(housing_units / ALAND10), 
           urbhouseden = Winsorize(house_urban / ALAND10)) %>%
    filter(stab!='AK' & stab!='HI') %>%
    filter(msaname != '99999') #keep only zcta in metropolitan areas 
  
  st_crs(zcta_map) <- 4326
  us_boundary <- map_data('state')
  us_boundary <- sfheaders::sf_multipolygon(map_data('state'), x = 'long', y = 'lat', multipolygon_id = 'group')
  st_crs(us_boundary) <-4326
  
  plot <- ggplot() + 
    geom_sf(data = zcta_map, color = 'transparent', aes(fill = get(target_demo))) + 
    geom_sf(data = us_boundary, fill= NA, size = 1.5) +
    theme_void() + 
    theme(aspect.ratio = 0.6) + 
    scale_fill_gradient(
      low = seecol(pal_seeblau, hex = T)[1], 
      high = seecol(pal_petrol, hex = T)[5],
      name = legend_name, 
      aesthetics = 'fill',
      guide = guide_colorbar(direction = "horizontal",
                             barheight = unit(2, units = "cm"),
                             barwidth = unit(50, units = "cm"),
                             draw.ulim = T,
                             draw.llim = T,
                             title.position = 'top',
                             title.hjust = 0.5,
                             label.hjust = 0.5), 
      na.value = 'gray') + 
    theme(legend.position = "bottom", 
          legend.title = element_text(size = 80),
          legend.text = element_text(size = 80))
  return(plot)
}




plot_changes_city <- function(target_var,
                              target_msa, 
                              mwarea, 
                              mwdate, 
                              plotname, 
                              df_data, 
                              nmon,
                              zctamsa, 
                              zipzcta,
                              zctaplace,
                              out) {
  nmonths <- nmon
  nmonths2 <- nmonths + 1 # keep t-1 for computing percentage change
  
  #identify main variable to plot: % change in rents after last MW change
  df_target <- df_data[data.table::like(vector = msa, pattern = target_msa), 
                       c('zipcode', 'countyfips', 'year_month', 'msa', 'place_code',
                         'medrentpricepsqft_sfcc', 'actual_mw', 'dactual_mw', 
                         'exp_mw_totjob')]
  df_target <- df_target[, Fyear_month := shift(year_month, type = 'lead'), by = zipcode]
  df_target <- df_target[Fyear_month >= as.Date(mwdate), ]
  df_target <- df_target[df_target[, .I[1:nmonths2], zipcode]$V1]
  df_target[, pct_target := (get(target_var)[.N] - get(target_var)[1])/get(target_var)[1], by = 'zipcode']
  df_target <- df_target[, last(.SD), by = zipcode]
  #double condition if mw
  # df_target <- df_target[!is.na(pct_target),]
  df_target <- df_target[!is.na(medrentpricepsqft_sfcc),]
  df_target[, 'region' := zipcode]
  #winsor if rent?
  if (target_var=='medrentpricepsqft_sfcc') {
    df_target[, pct_target := round(Winsorize(pct_target)*100, digits = 2)] #winsorize at .05 and .95
  } else {
    df_target[, pct_target := round(pct_mwch*100, digits = 2)]  
  }
  
  data(zip.map)
  zcta_map <- sfheaders::sf_multipolygon(zip.map, x = 'long', y = 'lat', multipolygon_id = 'id', polygon_id = 'piece', keep = T)
  
  zcta_sample_map <- inner_join(zcta_map, df_target, on = 'region')
  st_crs(zcta_sample_map) <- 4326
  
  msa_map <- zctamsa[data.table::like(vector = msaname, pattern = target_msa), ]
  msa_map <- inner_join(zcta_map, msa_map, by = c('region' = 'zcta'))
  st_crs(msa_map) <-4326
  
  mw_map <- inner_join(msa_map, zctaplace, by = c('region' = 'zcta'))
  mw_map <- mw_map[mw_map$place_code==mwarea,]
  mw_map <- st_union(mw_map)
  
  #define color palette over fixed interval
  minVal = min(df_target$pct_target, na.rm = T)
  maxVal = max(df_target$pct_target, na.rm = T)
  
  if (grepl('mw', target_var)==T){
    legend_name <- "6-Months Rent Change (%)"
    legend_width <- 50
  } else {
    legend_name <- "6-Months Minimum Wage Change (%)"
    legend_width <- 70
  }
  
  plot <- ggplot() + 
    geom_sf(data = msa_map, color = 'black', fill = 'transparent', size = 1.5) +  
    geom_sf(data = zcta_sample_map, aes(fill=pct_target), color="white", size = 1.5) +
    #geom_sf(data = mw_map, color = 'darkred', fill = 'transparent', size = 5) +
    theme_void() +
    theme(panel.grid.major = element_line(colour = 'transparent')) +
    scale_fill_gradient(
      low = seecol(pal_petrol, hex = T)[1], 
      high = seecol(pal_petrol, hex = T)[5],
      limits = c(minVal, maxVal),
      name = legend_name, 
      aesthetics = 'fill',
      guide = guide_colorbar(direction = "horizontal",
                             barheight = unit(2, units = "cm"),
                             barwidth = unit(legend_width, units = "cm"),
                             draw.ulim = T,
                             draw.llim = T,
                             title.position = 'top',
                             title.hjust = 0.5,
                             label.hjust = 0.5), 
      na.value = 'gray') +
    labs(title=plotname, subtitle = paste0('MW change date: ', mwdate)) +
    theme(legend.position = "bottom",
          plot.title = element_text(size=180),
          plot.subtitle = element_text(size = 140),
          legend.title = element_text(size = 120),
          legend.text = element_text(size = 80))

  return(plot)
}

plot_mw_changes_city <- function(target_var,
                              target_msa, 
                              mwarea, 
                              mwdate, 
                              plotname, 
                              df_data, 
                              nmon,
                              zctamsa, 
                              zipzcta,
                              zctaplace,
                              out) {
  nmonths <- nmon
  nmonths2 <- nmonths + 1 # keep t-1 for computing percentage change
  
  #identify main variable to plot: % change in rents after last MW change
  df_target <- df_data[data.table::like(vector = msa, pattern = target_msa), 
                       c('zipcode', 'countyfips', 'year_month', 'msa', 'place_code',
                         'medrentpricepsqft_sfcc', 'actual_mw', 'dactual_mw', 
                         'exp_mw_totjob')]
  df_target <- df_target[, Fyear_month := shift(year_month, type = 'lead'), by = zipcode]
  df_target <- df_target[Fyear_month >= as.Date(mwdate), ]
  df_target <- df_target[df_target[, .I[1:nmonths2], zipcode]$V1]
  df_target[, pct_mwch := (get(target_var)[.N] - get(target_var)[1])/get(target_var)[1], by = 'zipcode']
  df_target <- df_target[, last(.SD), by = zipcode]
  df_target <- df_target[!is.na(pct_mwch) & !is.na(medrentpricepsqft_sfcc),]
  df_target[, 'region' := zipcode]
  df_target[, pct_mwch := round(pct_mwch*100, digits = 2)]  

  data(zip.map)
  zcta_map <- sfheaders::sf_multipolygon(zip.map, x = 'long', y = 'lat', multipolygon_id = 'id', polygon_id = 'piece', keep = T)
  
  zcta_sample_map <- inner_join(zcta_map, df_target, on = 'region')
  st_crs(zcta_sample_map) <- 4326
  
  msa_map <- zctamsa[data.table::like(vector = msaname, pattern = target_msa), ]
  msa_map <- inner_join(zcta_map, msa_map, by = c('region' = 'zcta'))
  st_crs(msa_map) <-4326
  
  mw_map <- inner_join(msa_map, zctaplace, by = c('region' = 'zcta'))
  mw_map <- mw_map[mw_map$place_code==mwarea,]
  mw_map <- st_union(mw_map)

  minVal = min(df_target$pct_mwch, na.rm = T)
  maxVal = max(df_target$pct_mwch, na.rm = T)

  plot <- ggplot() + 
    geom_sf(data = msa_map, color = 'black', fill = 'transparent', size = 1.5) +  
    geom_sf(data = zcta_sample_map, aes(fill=pct_mwch), color="white", size =1.5) +
    theme_void() +
    theme(panel.grid.major = element_line(colour = 'transparent')) +
    scale_fill_gradient(
      low = seecol(pal_petrol, hex = T)[1], 
      high = seecol(pal_petrol, hex = T)[5],
      limits = c(minVal, maxVal),
      name = "6-Months Minimum Wage Change (%)", 
      aesthetics = 'fill',
      guide = guide_colorbar(direction = "horizontal",
                             barheight = unit(2, units = "cm"),
                             barwidth = unit(70, units = "cm"),
                             draw.ulim = T,
                             draw.llim = T,
                             title.position = 'top',
                             title.hjust = 0.5,
                             label.hjust = 0.5), 
      na.value = 'gray') +
    labs(title=plotname, subtitle = paste0('MW change date: ', mwdate)) +
    theme(legend.position = "bottom",
          plot.title = element_text(size=180),
          plot.subtitle = element_text(size = 140),
          legend.title = element_text(size = 120),
          legend.text = element_text(size = 80))
  
  return(plot)
}
  
df <- read.dta13(paste0(datadir, 'unbal_rent_panel.dta'))
df <- setDT(df)
df[, countyfips := str_pad(as.character(countyfips), 5, pad = 0)]
df[, zipcode := str_pad(as.character(zipcode), 5, pad = 0)]
df[, year_month := fromStataTime(year_month, '%tm')]
df <- df[, .(year_month, statefips, countyfips, county, place_code, msa, zipcode, 
             medrentpricepsqft_sfcc, state_mw, county_mw, local_mw, actual_mw, dactual_mw, mw_event, which_mw, exp_mw_totjob)]


xwalks <- make_xwalks()
zip_zcta_xwalk <- xwalks[['zip_zcta_xwalk']]
zcta_place_xwalk <- xwalks[['zcta_place_xwalk']]
zcta_msa_xwalk <- xwalks[['zcta_msa_xwalk']]
zip_county <- xwalks[['zip_county']]


png(filename = paste0(outdir, 'sample_map.png'), width = 7680, height = 5680)
plot_sample(df_data = df, zipzcta = zip_zcta_xwalk, out = outdir, zctamsa = zcta_msa_xwalk)
dev.off()

png(filename = paste0(outdir, 'popurban_density_map.png'), width = 7680, height = 5680)
plot_demo(out = outdir, zctamsa = zcta_msa_xwalk, target_demo = 'urbpopden', legend_name = 'Urban Population Density (per Sq. Miles)')
dev.off()


# L.A. MSA
png(filename = paste0(outdir, 'Los_Angeles_msa.png'), width = 7680, height = 7680)
plot_changes_city(target_var = 'medrentpricepsqft_sfcc', 
                target_msa = "Los Angeles",
                nmon = 6,
                plotname = "Los Angeles MSA",
                df_data = df,
                mwarea = 44000,
                mwdate = '2019-07-01',
                zctamsa = zcta_msa_xwalk,
                zipzcta = zip_zcta_xwalk,
                zctaplace = zcta_place_xwalk,
                out = outdir)
dev.off()
png(filename = paste0(outdir, 'Los_Angeles_msa_mw.png'), width = 7680, height = 7680)
plot_changes_city(target_var = 'actual_mw', 
                 target_msa = "Los Angeles",
                 nmon = 6,
                 plotname = "Los Angeles MSA",
                 df_data = df,
                 mwarea = 44000,
                 mwdate = '2019-07-01',
                 zctamsa = zcta_msa_xwalk,
                 zipzcta = zip_zcta_xwalk,
                 zctaplace = zcta_place_xwalk,
                 out = outdir)
dev.off()
png(filename = paste0(outdir, 'Los_Angeles_msa_expmw.png'), width = 7680, height = 7680)
plot_changes_city(target_var = 'exp_mw_totjob', 
                     target_msa = "Los Angeles",
                     nmon = 6,
                     plotname = "Los Angeles MSA",
                     df_data = df,
                     mwarea = 44000,
                     mwdate = '2019-07-01',
                     zctamsa = zcta_msa_xwalk,
                     zipzcta = zip_zcta_xwalk,
                     zctaplace = zcta_place_xwalk,
                     out = outdir)
dev.off()

# Seattle MSA
png(filename = paste0(outdir, 'Seattle_msa.png'), width = 7680, height = 7680)
plot_changes_city(target_var = 'medrentpricepsqft_sfcc',
           target_msa = "Seattle",
           nmon = 6,
           plotname = "Seattle MSA",
           df_data = df,
           mwarea = 63000,
           mwdate = '2019-01-01',
           zctamsa = zcta_msa_xwalk,
           zipzcta = zip_zcta_xwalk,
           zctaplace = zcta_place_xwalk,
           out = outdir)
dev.off()
png(filename = paste0(outdir, 'Seattle_msa_mw.png'), width = 7680, height = 7680)
plot_mw_changes_city(target_var = 'actual_mw',
                  target_msa = "Seattle",
                  nmon = 6,
                  plotname = "Seattle MSA",
                  df_data = df,
                  mwarea = 63000,
                  mwdate = '2019-01-01',
                  zctamsa = zcta_msa_xwalk,
                  zipzcta = zip_zcta_xwalk,
                  zctaplace = zcta_place_xwalk,
                  out = outdir)
dev.off()
png(filename = paste0(outdir, 'Seattle_msa_expmw.png'), width = 7680, height = 7680)
plot_mw_changes_city(target_var = 'exp_mw_totjob',
                     target_msa = "Seattle",
                     nmon = 6,
                     plotname = "Seattle MSA",
                     df_data = df,
                     mwarea = 63000,
                     mwdate = '2019-01-01',
                     zctamsa = zcta_msa_xwalk,
                     zipzcta = zip_zcta_xwalk,
                     zctaplace = zcta_place_xwalk,
                     out = outdir)
dev.off()

# Chicago MSA (cook county increase MW in July 2019)
png(filename = paste0(outdir, 'Chicago_msa.png'), width = 7680, height = 7680)
plot_changes_city(target_var = 'medrentpricepsqft_sfcc',
                  target_msa = "Chicago",
                  nmon = 6,
                  plotname = "Chicago MSA",
                  df_data = df,
                  mwarea = 14000,
                  mwdate = '2019-07-01',
                  zctamsa = zcta_msa_xwalk,
                  zipzcta = zip_zcta_xwalk,
                  zctaplace = zcta_place_xwalk,
                  out = outdir)
dev.off()


png(filename = paste0(outdir, 'Chicago_msa_mw.png'), width = 7680, height = 7680)
plot_mw_changes_city(target_var = 'actual_mw',
                     target_msa = "Chicago",
                     nmon = 6,
                     plotname = "Chicago MSA",
                     df_data = df,
                     mwarea = 14000,
                     mwdate = '2019-07-01',
                     zctamsa = zcta_msa_xwalk,
                     zipzcta = zip_zcta_xwalk,
                     zctaplace = zcta_place_xwalk,
                     out = outdir)
dev.off()
png(filename = paste0(outdir, 'Chicago_msa_expmw.png'), width = 7680, height = 7680)
plot_mw_changes_city(target_var = 'exp_mw_totjob',
                     target_msa = "Chicago",
                     nmon = 6,
                     plotname = "Chicago MSA",
                     df_data = df,
                     mwarea = 14000,
                     mwdate = '2019-07-01',
                     zctamsa = zcta_msa_xwalk,
                     zipzcta = zip_zcta_xwalk,
                     zctaplace = zcta_place_xwalk,
                     out = outdir)
dev.off()

# SF msa
png(filename = paste0(outdir, 'San_Francisco_msa.png'), width = 7680, height = 7680)
plot_changes_city(target_var = 'medrentpricepsqft_sfcc',
                target_msa = "San Francisco",
                nmon = 6,
                plotname = "San Francisco MSA",
                df_data = df,
                mwarea = 67000,
                mwdate = '2019-07-01',
                zctamsa = zcta_msa_xwalk,
                zipzcta = zip_zcta_xwalk,
                zctaplace = zcta_place_xwalk,
                out = outdir)
dev.off()
png(filename = paste0(outdir, 'San_Francisco_msa_mw.png'), width = 7680, height = 7680)
plot_mw_changes_city(target_var = 'actual_mw',
                  target_msa = "San Francisco",
                  nmon = 6,
                  plotname = "San Francisco MSA",
                  df_data = df,
                  mwarea = 67000,
                  mwdate = '2019-07-01',
                  zctamsa = zcta_msa_xwalk,
                  zipzcta = zip_zcta_xwalk,
                  zctaplace = zcta_place_xwalk,
                  out = outdir)
dev.off()
png(filename = paste0(outdir, 'San_Francisco_msa_expmw.png'), width = 7680, height = 7680)
plot_mw_changes_city(target_var = 'exp_mw_totjob',
                     target_msa = "San Francisco",
                     nmon = 6,
                     plotname = "San Francisco MSA",
                     df_data = df,
                     mwarea = 67000,
                     mwdate = '2019-07-01',
                     zctamsa = zcta_msa_xwalk,
                     zipzcta = zip_zcta_xwalk,
                     zctaplace = zcta_place_xwalk,
                     out = outdir)
dev.off()

#San Diego
png(filename = paste0(outdir, 'San_Diego_msa.png'), width = 7680, height = 7680)
plot_changes_city(target_var = 'medrentpricepsqft_sfcc',
           target_msa = "San Diego",
           mwarea = 66000,
           nmon = 6,
           plotname = "San Diego MSA",
           df_data = df,
           mwdate = '2019-01-01',
           zctamsa = zcta_msa_xwalk,
           zipzcta = zip_zcta_xwalk,
           zctaplace = zcta_place_xwalk,
           out = outdir)
dev.off()
png(filename = paste0(outdir, 'San_Diego_msa_mw.png'), width = 7680, height = 7680)
plot_mw_changes_city(target_var = 'actual_mw',
                  target_msa = "San Diego",
                  mwarea = 66000,
                  nmon = 6,
                  plotname = "San Diego MSA",
                  df_data = df,
                  mwdate = '2019-01-01',
                  zctamsa = zcta_msa_xwalk,
                  zipzcta = zip_zcta_xwalk,
                  zctaplace = zcta_place_xwalk,
                  out = outdir)
dev.off()
png(filename = paste0(outdir, 'San_Diego_msa_expmw.png'), width = 7680, height = 7680)
plot_mw_changes_city(target_var = 'exp_mw_totjob',
                     target_msa = "San Diego",
                     mwarea = 66000,
                     nmon = 6,
                     plotname = "San Diego MSA",
                     df_data = df,
                     mwdate = '2019-01-01',
                     zctamsa = zcta_msa_xwalk,
                     zipzcta = zip_zcta_xwalk,
                     zctaplace = zcta_place_xwalk,
                     out = outdir)
dev.off()











