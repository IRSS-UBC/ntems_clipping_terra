start_time <- Sys.time()
library("tidyverse")
library("terra")
library("sf")

# temp file locations
terra_temp <-
  "D:\\Temp" # save in variable because used in ntems_mosaic_gdal()

terraOptions(
  memfrac = 0.75,
  tempdir = terra_temp,
  todisk = FALSE,
  progress = 100
)

#### user inputs ####
aoi_path <-
  "Z:\\ByUser\\Muise\\francois4\\Shapefiles\\Study_Area_M_nineS.shp"

listed_shps <-
  list.files(
    "Z:/ByUser/Muise/francois4",
    full.names = T,
    pattern = ".shp$"
  )

for (aoi_path in listed_shps) {
  outpath <- dirname(aoi_path) %>%
    here::here(tools::file_path_sans_ext(basename(aoi_path)))
  
  # if you want a custom outpath, comment out if you want in the same folder
  #outpath <- "D:\\Bud\\francois"
  
  years <- c(1984:2019)
  years <- 2021
  
  # what to process?
  vars <-
    tibble(
      VLCE = T,
      # note - VLCE is always required when processing structure layers
      
      proxies = F,
      
      change_attribution = F,
      change_metrics = F,
      change_annual = F,
      
      species = F,
      
      age = F,
      
      topography = F,
      
      lat = F,
      lon = F,
      
      climate = F,
      
      structure_basal_area = T,
      structure_elev_cv = T,
      structure_elev_mean = T,
      structure_elev_p95 = T,
      structure_elev_stddev = T,
      structure_gross_stem_volume = T,
      structure_loreys_height = T,
      structure_percentage_first_returns_above_2m = T,
      structure_percentage_first_returns_above_mean = T,
      structure_total_biomass = T
    ) %>%
    pivot_longer(cols = everything()) %>%
    filter(value) %>%
    pull(name)
  
  # a template raster to project to. currently, if the region is >1 UTM zone, defaults to LCC
  template <-
    rast("D:\\Bud\\template_raster\\CA_forest_VLCE_2015.tif")
  #template <- rast("Z:\\ByUser\\Muise\\bc-vlce-2015.tif")
  
  #### end user inputs ####
  
  # processing from here on, user not to adjust unless they are confident in what they are doing
  aoi <- read_sf(aoi_path)
  
  # if single zone, out crs should be that utm zone
  out_crs <- st_crs(aoi)
  
  source(here::here("scripts", "get_utm_masks.R")) # generates utmzone_all
  source(here::here("scripts", "get_data_type.R")) # function to make sure files save properly, shamelessly stolen from piotr
  source(here::here("scripts", "ntems_crop.R"))
  
  
  
  to_process <- crossing(year = years, zone = utmzone_all, var = vars)
  
  source(here::here("scripts", "generate_process_df.R"))
  
  map2(process_df$path_in, process_df$path_out, ntems_crop)
  
  if (length(utm_masks) >= 2) {
    # this is just annoying regex to clean up the mosaic output names so we can then
    # split based on the mosaic paths to operate on everything using map
    # basically, sorry i did this to anyone who tries to read it in post
    # i've tried to add human readable comments, but regex is tough
    mosaic_dfs <- process_df %>%
      mutate(
        mosaic_path = str_replace(path_out, "[0-9]{1,2}[a-zA-Z]{1}", "mosaiced"),
        # regex that checks for 1-2 numbers, the 1 letter, and turns it to mosaiced
        mosaic_path = str_replace(mosaic_path, "UTM_[0-9]{1,2}[a-zA-Z]{1}_", ""),
        # regex that checks for UTM_ 1-2 numbers, then a letter, then an underscore, and removes it
        mosaic_path = str_replace(mosaic_path, "UTM[0-9]{1,2}[a-zA-Z]{1}_", ""),
        # regex that checks for UTM 1-2 numbers, then a letter, then and underscore, and removes it
        mosaic_path = str_replace(mosaic_path, "_[0-9]{1,2}[a-zA-Z]{1}_", "_"),
        # regex that checks for an underscore, 1-2 numbers, a letter, underscore, and replaces with an underscore
        mosaic_path = str_replace(mosaic_path, "_[0-9]{1,2}[a-zA-Z]{1}", "")
      ) %>%
      group_split(mosaic_path)
    
    source(here::here("scripts", "ntems_mosaic.R"))
    #source(here::here("scripts", "scripts/ntems_mosaic_gdal.R"))
    
    map(mosaic_dfs, ntems_mosaicer)
    #map(mosaic_dfs, ntems_mosaicer_gdal)
    
  }
  
  terra::tmpFiles(remove = T)
  print(Sys.time() - start_time)
}

