remove(list = ls())

library(sf)
library(data.table)
library(dplyr)
library(spData)
library(tmap)
library(tmaptools)
library(leaflet)
library(ggplot2)

USPS_zipcodes <- read_sf(dsn = "../../../drive/raw_data/shapefiles/USPS_zipcodes", 
                         layer = "USPS_zipcodes_July2020")
USPS_zipcodes <- USPS_zipcodes %>%
  select(ZIP_CODE, PO_NAME, STATE, POPULATION, SQMI, POP_SQMI) %>%
  rename(zipcode = ZIP_CODE, zipcode_name = PO_NAME,
         state_name = STATE, pop2020 = POPULATION, 
         area_sq_miles = SQMI, pop2020_per_sq_miles = POP_SQMI)

cbsa10_code_san_diego <- 41740
cbsa10_code_seattle <- 42660
mw_rent_data <- fread("../../../drive/derived_large/estimation_samples/all_zipcode_months.csv",
                      colClasses = c(zipcode ="character", place_code ="character", 
                                     countyfips = "character", cbsa10 = "character",
                                     zcta ="character", place_name = "character", 
                                     county_name = "character", cbsa10_name = "character",
                                     state_abb = "character", statefips = "character")) %>%
  filter((year == 2018 & month == 10) | (year == 2019 & month == 3)) %>%
  filter(cbsa10 == cbsa10_code_san_diego | cbsa10 == cbsa10_code_seattle) %>%
  select(zipcode, cbsa10, year, month, actual_mw, exp_ln_mw, medrentpricepsqft_SFCC) %>%
  mutate(ln_actual_mw = log(actual_mw),
         ln_rent_var = log(medrentpricepsqft_SFCC)) %>%
  group_by(zipcode, cbsa10) %>%
  summarise(change_actual_mw = last(actual_mw) - first(actual_mw), 
            change_ln_actual_mw = last(ln_actual_mw) - first(ln_actual_mw),
            change_exp_ln_mw = last(exp_ln_mw) - first(exp_ln_mw),
            change_ln_rents = last(ln_rent_var) - first(ln_rent_var))

merged <- left_join(USPS_zipcodes, mw_rent_data, by = "zipcode")
san_diego <- merged %>%
  filter(cbsa10 == cbsa10_code_san_diego)
seattle <- merged %>%
  filter(cbsa10 == cbsa10_code_seattle)

san_diego_ln_mw_change <- tm_shape(san_diego) + 
  tm_fill(col = "change_ln_actual_mw",
          title = "Change in log(MW)",
          style = "cont",
          palette = "BuGn") +
  tm_borders(lwd = .01, alpha = 0.5) +
  tm_layout(legend.position = c("left", "bottom"))
tmap_save(san_diego_ln_mw_change, 
          "../output/san_diego_ln_mw_change.png",
          dpi = 100)

san_diego_exp_ln_mw_change <- tm_shape(san_diego) + 
  tm_fill(col = "change_exp_ln_mw",
          title = "Change in experienced log(MW)",
          style = "cont",
          palette = "BuGn") +
  tm_borders(lwd = .01, alpha = 0.5) +
  tm_layout(legend.position = c("left", "bottom"))
tmap_save(san_diego_exp_ln_mw_change, 
          "../output/san_diego_exp_ln_mw_change.png",
          dpi = 100)

san_diego_ln_rents_change <- tm_shape(san_diego) + 
  tm_fill(col = "change_ln_rents",
          title = "Change in log(rents per square foot)",
          style = "cont",
          palette = "BuGn") +
  tm_borders(lwd = .01, alpha = 0.5) +
  tm_layout(legend.position = c("left", "bottom"))
tmap_save(san_diego_ln_rents_change, 
          "../output/san_diego_ln_rents_change.png",
          dpi = 100)

seattle_ln_mw_change <- tm_shape(seattle) + 
  tm_fill(col = "change_ln_actual_mw",
          title = "Change in log(MW)",
          style = "cont",
          palette = "BuGn") +
  tm_borders(lwd = .01, alpha = 0.5) +
  tm_layout(legend.position = c("left", "bottom"))
seattle_ln_mw_change
tmap_save(seattle_ln_mw_change, 
          "../output/seattle_ln_mw_change.png",
          dpi = 100)

seattle_exp_ln_mw_change <- tm_shape(seattle) + 
  tm_fill(col = "change_exp_ln_mw",
          title = "Change in experienced log(MW)",
          style = "cont",
          palette = "BuGn") +
  tm_borders(lwd = .01, alpha = 0.5) +
  tm_layout(legend.position = c("left", "bottom"))
tmap_save(seattle_exp_ln_mw_change, 
          "../output/seattle_exp_ln_mw_change.png",
          dpi = 100)

seattle_ln_rents_change <- tm_shape(seattle) + 
  tm_fill(col = "change_ln_rents",
          title = "Change in log(rents per square foot)",
          style = "cont",
          palette = "BuGn") +
  tm_borders(lwd = .01, alpha = 0.5) +
  tm_layout(legend.position = c("left", "bottom"))
seattle_ln_rents_change
tmap_save(seattle_ln_rents_change, 
          "../output/seattle_ln_rents_change.png",
          dpi = 100)
