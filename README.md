# Aquaculture
A suitability analysis for oyster aquaculture/farming on the East Coast (USA) using R and ArcGIS Pro. 

First, I worked in R to pull data and make a map of suitable areas using data from NASA's Jet Propulsion Laboratory and NOAA's National Centers for Environmental Information (NCEI). I wasn't satisfied with the resolution and decided to move to ArcGIS Pro for the project since I'm a bit more comfortable there.

Then, I struggled to find neat data layers for oceanographic data to pull into ArcGIS Pro. Many data layers were spatially and/or temporally large, covering the whole ocean since the 1970s. This led me to use R to clean the data before pulling it into ArcGIS Pro. I'm much happier with this process and the resulting data.

## Here is an overview of the next steps in my ArcGIS Pro workflow:
## Source & Download Data
- Sea Surface Temperature (SST) - NOAA's Physical Sciences Laboratory
  - Data from 2025, cleaned in R
- Salinity Data - NOAA's National Centers for Environmental Information (NCEI)
  - Data from 2015-2022, cleaned in R
- North Carolina Shellfish Growing Area Classifications - NCDEQ GIS Open Data Portal
  - downloaded as polygon layer
- Virginia Shellfish Safety - Virginia Department of Health
  - downloaded as KML file
- Navigation Channels - US Army Corps of Engineers
  - downloaded as polygon layer
- Storm Surge Risk Maps for Category 1/2 Hurricanes (SLOSH Model)- National Hurricane Center, NOAA
  - downloaded as raster layers
- Waterbodies - NHD via Esri Living Atlas 
- Coastline - NOAA Shoreline Data Explorer (Downloaded, but not sure if I'll end up using it)

## Clean and QC Data
- Added a field for VA and NC Shellfish Safety layers as a binary attribute addressing regulatory status. VA only notes waters that are closed, anything else is open. NC notes waters that are open and closed to harvesting. NC/VA polygon files were merged.
- In order to capture open areas in VA, a waterbodies dataset was imported, clipped to the study area, irrelevant waterbodies were removed (dams/lakes/etc) and those areas were given a value of 1 if they were not noted in the VA datset. Then, a union was performed on the waterbodies layer and the NC/VA Shellfish layer.
- Salinity and SST were interpolated to match the study area, as they did not cover bays/sounds/estuaries. Both layers were then resampled using bilinear interpolation to match the finer resolution (~10m) of the SLOSH Storm Surge Maps.
- Since this resulting resolution was quite high (is it too high? Maybe!), I only looked at the pixels closest to the shoreline in the SLOSH layers.
- The merged shoreline files (both N35W80 and N30W80) were simplified using a simplification tolerance of 30m and the Douglas-Peucker algorithm to reduce processing requirements.

## Workflow Tasks
- The Navigation Channels received a buffer of 100m to avoid designating shipping lanes as suitable for oyster farming.
- The simplified shoreline was buffered at 500m and then clipped with the NHD Waterbodies polygon layer so than only those areas in the water within 500m of shore are selected. *This had a major problem! Swamp/Marsh areas were not deleted with the initial Waterbodies cleaning and this resulted in lots of small lakes nearly 80 miles from the coast being included in the dataset.
  - To remedy this, I used Select by Location and selected those areas that were farther than 1 km from the shoreline. This helped, but still wasn't a perfect match because there were some "holes" in the shoreline data that would result in deletion of areas approved for harvest (in the Pamlico Sound, for example). So, with the select by location selection highlighted, I manually removed those inland areas still lit up (Pocosin Lakes, for example) and added those areas that were missed by the shoreline location selection (like the Pamlico Sound). This was definitely a disappointing setback and took a long time to rectify manually.
- Next, I ran distance allocation on the SLOSH Cat 1 inundation raster with my new Nearshore Oyster Zone layer as a mask. This produced a layer in the water (of my Nearshore Oyster Zone) that had the value of the nearest SLOSH inundation pixel, showing the areas of water where nearby land has high inundation risk.

### Reclassification and Rasterization
- A field was added to the Channel Buffer Layer to show that each area inside a polygon has a score of 0, so that in the final raster calculation, these areas will be excluded from ideal oyster areas. This layer was then rasterized. 
- SLOSH Inundation reclass Matrix comes from the idea that a small oyster reef may help attenuate *some* wave energy, but probably not a 15 foot storm surge. Ideally, an oyster reef would help mitigate 5-8 feet of inundation, while 0-2 feet can usually be handled by the existing environment since it's about the same as a high tide. 
  - 0-2 feet: 1
  - 3-4 feet: 3
  - 5-8 feet: 5
  - 9-11 feet: 3
  - 12-15 feet: 1
-Both SST and Salinity were reclassified to a scale where 5 is optimal and 1 is poor, using basics of oyster biology/habitat needs. 
- Salinity was reclassified using the following table:
  - 14	28	5
  - 28	35	3
  - 35	50	1
-  Sea Surface Temperature was reclassified using the following table:
  -  6   10	1
  -  10	15	2
  -  15	20	3
  -  20	23	4
  -  23	25	5
- The finalized Shellfish Safety and Waterbody Union was used as a mask on the final raster calcuation. The Raster Calculation for the Final Oysters Suitability Raster was:
    - (Reclass_SST * .25 + Reclass_SAL *.35 + Reclass_SLOSH *.40) * Final_Channel_Mask
    - This excludes navigational channels from the final raster by giving them a 0 value. The other parameters were given relatively equal weights, but since the SST and Salinity were not expected to change too much over the study area, the SLOSH was given the greatest weight. 

   
