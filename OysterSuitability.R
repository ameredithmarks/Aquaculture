# --- TNC Aquaculture Scientist Portfolio Project ---
# Goal: Identify Restorative Oyster Aquaculture Sites in NC
# Tools: sf, terra, tidyverse

library(sf)
library(terra)
library(tidyverse)
library(rerddap)

# 1. Load and Look at Temperature Data (ERDDAP)
data_info <- rerddap::info("jplMURSST41")
#print(data_info)

# 2. Pull just NC data. 
nc_sst <- griddap("jplMURSST41",
                  latitude = c(33.5, 36.5),
                  longitude = c(-78.5, -75.0),
                  time = c('2025-06-01', '2025-06-01'),
                  fields = "analysed_sst")

# 3. Convert to Raster
sst_df <- as.data.frame(nc_sst$data) %>%
  mutate(
    longitude = as.numeric(longitude),
    latitude = as.numeric(latitude),
    sst_celsius = as.numeric(analysed_sst)
  )

# Convert data frame to an sf spatial object
sst_points <- st_as_sf(sst_df, coords = c("longitude", "latitude"), 
                       crs = "EPSG:4326")

# Create a template matching boundaries of download
sst_template <- rast(ext(sst_points), res = 0.01, crs = "EPSG:4326")

# Put the values onto the grid to have a georeferenced raster
sst_raster <- rasterize(sst_points, sst_template, field = "sst_celsius", fun = mean)
                     
# 4. Visualize SST
plot(sst_raster, main = "Sea Surface Temp - NC Coast")

# 5. Temperature Suitability Score
# Based on basic review of oyster biology and ideal habitat conditions (Celsius)
# 0: Too Cold (<10)
# 1: Marginal (10-18)
# 2: Optimal (18-28)
# 1: Marginal (28-32)
# 0: Too Hot (>32)

temp_matrix <- matrix(c(
  0, 10, 0,
 10, 18, 1, 
 18, 28, 2,
 28, 32, 1,
 32, 50, 0
 ), ncol =3, byrow = TRUE)

temp_suitability <- classify(sst_raster, temp_matrix, include.lowest = TRUE)

# 6. Plot to visualize suitable areas
# The plot is expected to return only suitable areas, since the SST map has
# a range of 18 to 26, fully within the optimal range for oysters.
plot(temp_suitability[[1]], main = "Oyster Temperature Suitability (NC)")

# 7. Salinity
# Load the downloaded June NetCDF File
# woa23_decav_s06_01.nc
june_salinity_cube <- rast("woa23_decav_s06_01.nc")

# Metadata structure and check to see how time/depth are labeled
#print(june_salinity_cube)
#names(june_salinity_cube)

# Extract first layer only (surface salinity)
june_surface_salinity <- june_salinity_cube[[1]]

# Get spatial boundaries of the temp map and crop salinity map to match
target_extent <- ext(temp_suitability)

june_salinity_nc_coastal <- crop(june_surface_salinity, target_extent,
                                 snap = "near")
# Set CS to WGS84
crs(june_surface_salinity) <- "EPSG:4326"


# Resample June salinity data to match temperature grid
june_salinity_projected <- resample(june_salinity_nc_coastal, 
                                    temp_suitability,
                                    method = "bilinear")
# Double check that they match
#print(ext(june_salinity_projected) == ext(temp_suitability))
#print(res(june_salinity_projected) == res(temp_suitability))

# 8. Reclassify Salinity
# Based on basic oyster salinity needs to optimize growth and reduce
# and parasite susceptibility
# 0: Too low <10ppt
# 1: Borderline 10-14ppt
# 2: Optimal 14-20ppt
# 1: Borderline 20-28ppt
# 0: Too high >28ppt

#include.lowest = TRUE ensures boundaries are handled cleanly
salinity_matrix <- matrix(c(
  0, 10, 0, 
  10, 14, 1,
  14, 20, 2,
  20, 28, 1,
  28, 50, 0
), ncol = 3, byrow = TRUE)

# Classify the projected salinity raster
june_salinity_suitability <-classify(june_salinity_projected, 
                                     salinity_matrix,
                                     include.lowest = TRUE)

names(june_salinity_suitability) <- "salinity_suitability"

# 9. Combine Temp and Salinity in a Raster Math Overlay
# Max possible score is 4 (Temp = 2, Salinity = 2)
final_temp_score <- temp_suitability[[1]]
final_salinity_score <- june_salinity_suitability[[1]]

print("Verify Temp Score Max (Should be 2):")
print(global(final_temp_score, "max", na.rm = TRUE))

print("Verify Salinity Score Max (Should be 2):")
print(global(final_salinity_score, "max", na.rm = TRUE))

june_total_suitability <- final_temp_score + final_salinity_score
names(june_total_suitability) <- "total_suitability"

print("Total Suitability Range:")
print(global(june_total_suitability, "range", na.rm = TRUE))

# 10. Visualize the combined map!
# Color palette for scores 0 through 4
suitability_colors <- c("gray90", "tomato", "khaki", "lightgreen", "forestgreen")

# Plot final results
plot(june_total_suitability,
     col = suitability_colors,
     main = "Oyster Aquaculture Suitability: NC Coast (June)",
     xlab = "Longitude",
     ylab = "Latitude",
     pax = list(las = 1)) #to keep axis text horizontal

writeRaster(june_total_suitability, "NC_Oyster_Suitability_June.tif", overwrite = TRUE)

library(rnaturalearth)
library(rnaturalearthdata)

land <- ne_countries(scale = "medium", country = "united states of america",
                    returnclass = "sf" )
land_nc <- st_crop(land, st_bbox(c(xmin = -78.5, xmax = -75.0, ymin = 33.5, 
                                   ymax = 36.5), crs = 4326))

plot(june_total_suitability,
     col = c("gray90", "tomato", "khaki", "lightgreen", "forestgreen"),
     main = "Oyster Suitability (June)",
     xlab = "Longitude",
     ylab = "Latitude")

plot(st_geometry(land_nc), col = "gray40", border = "gray30", add = TRUE)

# Smooth out Suitability Map
june_smoothed <- focal(june_total_suitability, w = 3, fun = mean, na.rm = TRUE)

june_final_map <- round(june_smoothed)

plot(june_final_map,
      col = c("gray90", "tomato", "khaki", "lightgreen", "forestgreen"),
      breaks = c(-0.5, 0.5, 1.5, 2.5, 3.5, 4.5),
      main = "Oyster Aquaculture Suitability: NC Coast (June)",
      xlab = "Longitude", ylab = "Latitude")

plot(st_geometry(land_nc), col = "gray40", border = "gray30", add = TRUE)

#This map shows just a single block of semi-suitable area due to the resolution
#of the salinity layer. The entire coast of NC has suitable SST, so when layered
#with the only salinity value (which is too high and has a suitability score of 0),
#the final map just shows the area where the temperature is suitable. 
