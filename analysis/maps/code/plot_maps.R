remove(list = ls())

library(sf)
library(raster)
library(data.table)
library(dplyr)
library(spData)
library(spDataLarge)
library(tmap)
library(leaflet)
library(ggplot2)

USPS_zipcodes <- read_sf(dsn = "../../../drive/raw_data/shapefiles/USPS_zipcodes", 
                         layer = "USPS_zipcodes_July2020")
USPS_zipcodes <- USPS_zipcodes %>%
  select(ZIP_CODE, PO_NAME, STATE, POPULATION, SQMI, POP_SQMI) %>%
  rename(zipcode = ZIP_CODE, zipcode_name = PO_NAME,
         state_name = STATE, pop2020 = POPULATION, 
         area_sq_miles = SQMI, pop2020_per_sq_miles = POP_SQMI)

geo_master <- fread("../../../base/geo_master/output/zip_county_place_usps_master.csv",
                    colClasses = c("character", "character", "character", "character",
                                   "character", "character", "character", "character",
                                   "character", "character", "integer", "integer"))
merged <- left_join(USPS_zipcodes, geo_master, by = "zipcode") %>%
  filter(is.na(area_sq_miles) == FALSE)

merged_for_maps <- merged %>%
  filter(state_abb != "AK" & state_abb != "HI")

USPS_zipcodes_density_map <- tm_shape(merged_for_maps) + 
  tm_borders("white", lwd = .5) + 
  tm_fill(col = "pop2020_per_sq_miles",
          title = "Population density") +
  tmap_mode("plot")
USPS_zipcodes_density_map
tmap_save(USPS_zipcodes_density_map, 
          "../output/USPS_zipcodes_pop_density.png")

mw_rent_data <- fread("../../../drive/derived_large/estimation_samples/baseline_zipcode_months.csv")

# chicago_home_assignment_lost <- tm_shape(chicago_met_tracts) + 
#   tm_borders() + 
#   tm_fill(col = "pop_coverage_lost", 
#           breaks = c(0, 0.025, 0.05, 0.075, 0.1, 
#                      0.125, 0.15, 0.175, 0.2, 
#                      0.225, 0.25, 0.275, 0.30, 0.40, 
#                      0.5, 0.6, 0.7, 0.8, 0.9, 1, 50),
#           palette = "viridis",
#           title = "Share of population covered") +
#   tm_layout(legend.position = c("right", "top"), 
#             legend.width = 0.18,
#             legend.height = 0.4,
#             inner.margins = -0.2) +
#   tmap_mode("plot")
# chicago_home_assignment_lost
# tmap_save(chicago_home_assignment_lost, 
#           "../output/chicago_home_assignment_lost_map.png")