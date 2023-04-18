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
  "Z:\\ByUser\\Muise/francois4/extent_BAP/extent.shp"


outpath <- dirname(aoi_path) %>%
  here::here(tools::file_path_sans_ext(basename(aoi_path)))

# if you want a custom outpath, comment out if you want in the same folder
# outpath <- "D:\\Bud\\bap_alex"

years <- c(1984:2019)
years <- 2014

# what to process?
vars <-
  tibble(
    VLCE = T,
    # note - VLCE is always required when processing structure layers
    
    proxies = F,
    
    change_attribution = F,
    change_metrics = F,
    change_annual = F,
    
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
template <- rast("Z:\\ByUser\\Muise\\bc-vlce-2015.tif")

#### end user inputs ####

# processing from here on, user not to adjust unless they are confident in what they are doing
aoi <- read_sf(aoi_path)

split_polys <- aoi %>%
  janitor::clean_names() %>%
  group_by(prot_name) %>%
  group_split(prot_name)

save_loc <- here::here(dirname(aoi_path), "split_shps")
dir.create(save_loc)

save_named <- function(df, colname) {
  save_name <- df %>% pull(colname) %>%
    str_to_lower() %>%
    str_replace_all("[^[:alnum:]]", "_")
  save_path <- here::here(save_loc, paste0(save_name, ".shp"))
  
  st_write(df, save_path, append = F)
  return(save_path)
}

input_list <- map(split_polys, save_named, colname = "prot_name")

for (aoi_path in input_list) {
  print(aoi_path)
  outpath <- dirname(aoi_path) %>%
    here::here(tools::file_path_sans_ext(basename(aoi_path)))
  aoi <- read_sf(aoi_path) %>%
    st_make_valid()
  
  
  
  # if single zone, out crs should be that utm zone
  out_crs <- st_crs(aoi)
  
  source(here::here("scripts", "get_utm_masks.R")) # generates utmzone_all
  source(here::here("scripts", "get_data_type.R")) # function to make sure files save properly, shamelessly stolen from piotr
  source(here::here("scripts", "ntems_crop.R"))
  
  
  
  to_process <-
    crossing(year = years, zone = utmzone_all, var = vars)
  
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
        mosaic_path = str_replace(mosaic_path, "_[0-9]{1,2}[a-zA-Z]{1}_", "_")
        # regex that checks for an underscore, 1-2 numbers, a letter, underscore, and replaces with an underscore
      ) %>%
      group_split(mosaic_path)
    
    source(here::here("scripts", "ntems_mosaic.R"))
    #source(here::here("scripts", "scripts/ntems_mosaic_gdal.R"))
    
    map(mosaic_dfs, ntems_mosaicer)
    #map(mosaic_dfs, ntems_mosaicer_gdal)
    
  }
  
  terra::tmpFiles(remove = T)
}

colour_match <- function(rast, in_name) {
  if (!str_detect(in_name, "VLCE|Attribution")) {
    #print("did not detect VLCE | Attribution")
    return(rast)
  }
  ref <- rast(in_name)
  levels(rast) <- levels(ref)
  coltab(rast) <- coltab(ref)
  rast
}

# align all split polygon rasters to the same template raster

for (rasts_path in list.dirs(save_loc, recursive = F)) {
  print(rasts_path)
  
  in_names <- list.files(
    rasts_path,
    pattern = ".dat$",
    recursive = T,
    full.names = T
  ) %>%
    str_subset("/[0-9]{1,2}[a-zA-Z]{1}")
  
  out_names <- in_names %>%
    str_replace("[0-9]{1,2}[a-zA-Z]{1}", "mosaiced") %>%
    str_replace("UTM_[0-9]{1,2}[a-zA-Z]{1}_", "") %>%
    str_replace("UTM[0-9]{1,2}[a-zA-Z]{1}_", "") %>%
    str_replace("_[0-9]{1,2}[a-zA-Z]{1}_", "_")
  
  mosaic_exists <- out_names %>%
    file.exists() %>%
    all()
  
  if (mosaic_exists) {
    print("already mosaiced/transformed")
    next()
  }
  
  out_names %>%
    dirname() %>%
    map(dir.create, recursive = T, showWarnings = F)
  
  projected <- in_names %>%
    map(.f = rast) %>%
    map(project,
        y = template,
        method = "near",
        align = T) %>%
    map2(.x = .,
         .y = in_names,
         .f = colour_match) %>%
    map2(
      .x = .,
      .y = out_names,
      .f = writeRaster,
      filetype = "envi",
      overwrite = T
    )
  print("saved")
}

print(Sys.time() - start_time)
