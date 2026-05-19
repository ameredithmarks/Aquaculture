## Aquaculture
A suitability analysis for oyster aquaculture/farming on the East Coast (USA) using R and ArcGIS Pro. 

First, I worked in R to pull data and make a map of suitable areas using data from NASA's Jet Propulsion Laboratory and NOAA's National Centers for Environmental Information (NCEI). I wasn't satisfied with the resolution and decided to move to ArcGIS Pro for the project since I'm a bit more comfortable there.

Then, I struggled to find neat data layers for oceanographic data to pull into ArcGIS Pro. Many data layers were spatially and/or temporally large, covering the whole ocean since the 1970s. This led me to use R to clean the data before pulling it into ArcGIS Pro. I'm much happier with this process and the resulting data.

## Here is an overview of the next steps in my ArcGIS Pro workflow:
# Source & Download Data
- Sea Surface Temperature (SST) - NOAA's Physical Sciences Laboratory
-   cleaned in R
- Salinity Data - NOAA's National Centers for Environmental Information (NCEI)
-   cleaned in R
- North Carolina Shellfish Growing Area Classifications - NCDEQ GIS Open Data Portal
-   downloaded as polygon layer
- Virginia Shellfish Safety - Virginia Department of Health
-   downloaded as KML file
- Navigation Channels - US Army Corps of Engineers
-   downloaded as polygon layer
- Storm Surge Risk Maps for Category 1/2 Hurricanes (SLOSH Model)- National Hurricane Center, NOAA
-   downloaded as raster layers
- Waterbodies - NHD

# Clean and QC Data
- Added a field for VA and NC Shellfish Safety layers as a binary attribute addressing regulatory status. VA only notes waters that are closed, anything else is open. NC notes waters that are open and closed to harvesting. NC/VA polygon files were merged.
- In order to capture open areas in VA, a waterbodies dataset was imported, clipped to the study area, irrelevant waterbodies were removed (dams/lakes/etc) and those areas were given a value of 1 if they were not noted in the VA datset. Then, a union was performed on the waterbodies layer and the NC/VA Shellfish layer.
- Salinity and SST were interpolated to match the study area, as they did not cover bays/sounds/estuaries. Both layers were then resampled using bilinear interpolation to match the finer resolution (~10m) of the SLOSH Storm Surge Maps.

# Buffering and Vector > Raster
- The Navigation Channels received a buffer of 100m to avoid designating shipping lanes as suitable for oyster farming. Then this polygon layer was rasterized. 
- The finalized Shellfish Safety and Waterbody Union was rasterized based on its regulatory score field.

  
