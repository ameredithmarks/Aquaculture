# --- TNC Aquaculture Scientist Portfolio Project ---
# Goal: Identify Restorative Oyster Aquaculture Sites in NC
# Tools: sf, terra, tidyverse

library(sf)
library(terra)
library(tidyverse)
library(rerddap)

# 1. Load and Look at Temperature Data (ERDDAP)
data_info <- rerddap::info("jplMURSST41")
print(data_info)

# 2. Pull just NC data. 
nc_sst <- griddap("jplMURSST41",
                  latitude = c(33.5, 36.5),
                  longitude = c(-78.5, -75.0),
                  time = c('2025-06-01', '2025-06-01'),
                  fields = "analysed_sst")

# 3. Convert to Raster
sst_raster <- rast(nc_sst$data)

# 4. Visualize SST
plot(sst_raster, main = "Sea Surface Temp - NC Coast")

# 5. Temperature Suitability Score
# Based on basic review of oyster biology and ideal habitat conditions (Celsius)
# 0: Too Cold (<10)
# 1: Marginal (10-18)
# 2: Optimal (18-28)
# 1: Marginal (28-32)
# 0: Too Hot (>32)

temp_suitability <- classify(sst_raster, c(0, 10, 0,
                                           10, 18, 1, 
                                           18, 28, 2,
                                           28, 32, 1,
                                           32, 50, 0))
# 6. Plot to visualize suitable areas
# The plot is expected to return only suitable areas, since the SST map has
# a range of 18 to 26, fully within the optimal range for oysters.
plot(temp_suitability, main = "Oyster Temperature Suitability (NC)")

# 7. Salinity
