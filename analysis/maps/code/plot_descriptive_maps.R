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

zipcodes <- fread("../../../drive/derived_large/zipcode/zipcode_cross.csv",
                    colClasses = c(zipcode ="character", place_code ="character", 
                                   countyfips = "character", cbsa10 = "character",
                                   zcta ="character", place_name = "character", 
                                   county_name = "character", cbsa10_name = "character",
                                   state_abb = "character", statefips = "character"))
merged <- left_join(USPS_zipcodes, zipcodes, by = "zipcode") %>%
  filter(is.na(area_sq_miles) == FALSE) %>%
  mutate(in_zillow = case_when(n_months_zillow_rents > 0 ~ 1,
                               TRUE ~ 0))

matched <- merged %>%
  filter(is.na(houses_zcta_place_county) == FALSE)

merged_for_maps <- merged %>%
  filter(state_abb != "AK" & state_abb != "HI")

# test <- merged_for_maps%>%
#   filter(state_abb == "NY")

USPS_zipcodes_density_map <- tm_shape(merged_for_maps) + 
  tm_fill(col = "pop2020_per_sq_miles",
          title = "Population density",
          style = "quantile",
          n = 10,
          palette = "Reds") +
  tm_borders(lwd = .0001, alpha = 0.1) +
  tmap_mode("plot") + tmap_options(check.and.fix = TRUE)
USPS_zipcodes_density_map
tmap_save(USPS_zipcodes_density_map, 
          "../output/USPS_zipcodes_pop_density.png",
          dpi = 100)

USPS_zipcodes_zillow_data <- tm_shape(merged_for_maps) + 
  tm_fill(col = "in_zillow",
          title = "Has Zillow rents data",
          style ="cat", 
          palette = "BuGn") +
  tm_borders(lwd = .0001, alpha = 0.1) +
  tmap_mode("plot") + tmap_options(check.and.fix = TRUE)
USPS_zipcodes_zillow_data
tmap_save(USPS_zipcodes_zillow_data, 
          "../output/USPS_zipcodes_zillow_data.png",
          dpi = 100)