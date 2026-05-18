# An attempt to clean ocean data for the aquaculture project to be completed
# in ArcGIS Pro

library(terra)
#setwd("YOUR_WORKING_DIRECTORY")

# Temperature 
# 1. Load NetCDF File
sst_raw <- rast("C:/RStudioPractice/sst.day.mean.2025.nc")
# If the NetCDF has multiple layers, just look at the first one
sst_single <- sst_raw[[1]]

# 2. Force the raster's CRS to a standard WGS84 Long/Lat
crs(sst_single) <- "+proj=longlat +datum=WGS84"


# 3. Check longitude scale of data
if (ext(sst_single)$xmin >= 0) {
  # 0 to 360 scale box
  vanc_extent <- ext(281, 286, 33, 38.5)
} else {
  #-180 to 180 scale box
  vanc_extent <- ext(-79, -74, 33, 38.5)
}

# 4. Crop to study area (NC/VA)
sst_cropped <- crop(sst_single, vanc_extent)

if (ext(sst_cropped)$xmin >= 180) {
  sst_cropped <-rotate (sst_cropped)
}

# 5. Save as a clean, standard local GeoTIFF
writeRaster(sst_cropped,
            filename= "C:/RStudioPractice/Aquaculture/sst_25.tif",
            overwrite = TRUE)

print("SST cropped and saved successfully!")


## Salinity
# 1. Load local Salinity NetCDF File
sal_raw <- rast("C:/RStudioPractice/woa23_B5C2_s05_04.nc")

# If it has multiple layers, just look at the first one. 
sal_single <- sal_raw[["s_an_depth=0_1"]]

#Double check to make sure values are in the 30-36 range
print(global(sal_single, fun="range", na.rm = TRUE))

# 2.Force the raster's CRS to a standard WGS84 Long/Lat
crs(sal_single) <- "+proj=longlat +datum=WGS84"

# 3. Check longitude scale of data
if (ext(sal_single)$xmin >= 0) {
  # 0 to 360 scale box
  vanc_extent <- ext(281, 286, 33, 38.5)
} else {
  #-180 to 180 scale box
  vanc_extent <- ext(-79, -74, 33, 38.5)
}

# 4. Crop to study area (NC/VA)
sal_cropped <- crop(sal_single, vanc_extent)

if (ext(sal_cropped)$xmin >= 180) {
  sal_cropped <-rotate (sal_cropped)
}

# 5. Save as a clean, standard local GeoTIFF
writeRaster(sal_cropped,
            filename= "C:/RStudioPractice/Aquaculture/Sal_May_2015_2022.tif",
            overwrite = TRUE)

print("Salinity cropped and saved successfully!")