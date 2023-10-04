# mosaic clipped ntems rasters together
# first must use the utm masks

ntems_mosaicer <- function(tibble) {
  mosaic_start <- Sys.time()
  
  year <- tibble %>%
    pull(year) %>%
    unique()
  
  var <- tibble %>%
    pull(var) %>%
    unique()
  
  save_path <- tibble %>%
    pull(mosaic_path) %>%
    unique()
  
  message()
  print("mosaicing ------------------")
  print(paste("zones:", toString(utmzone_all)))
  print(paste("year:", year))
  print(paste("variable:", var))
  print(paste("save path:", save_path))
  
  dir.create(dirname(save_path), showWarnings = F, recursive = T)
  
  ref <- tibble %>%
    head(1) %>%
    pull(path_out)
  
  dtype <- ref %>%
    get_data_type()
  
  print(paste("datatype:", dtype))
  #print(paste("mosaicing at: ", save_path))
  print("----------------------------")
  
  
  
  print("Projecting rasters and vector masks")
  
  utm_masks_proj <- utm_masks %>%
    map(project, y = template)
  
  rast_paths <- tibble %>%
    pull(path_out)

  proj_rasts <- rast_paths %>%
    map(rast) %>%
    map(.f = project, y = template,
         align = T, method = "near", gdal = T, by_util = T, threads = T)
  
  print("Masking")
  
  masked_data <- proj_rasts %>%
    map2(.x = ., .y = utm_masks_proj, .f = mask,
         todisk = T)
  
  print("Mosaicing")
  
  mosaiced <- masked_data %>%
    sprc() %>%
    mosaic(fun = "max")

  print("Mosaiced")
    
  if (var == "VLCE" | var == "change_attribution" | var == "change_annual") {
    
    # implement a direct header modification here
    print("Adding levels and colours")
    
    levels(mosaiced) <- levels(rast(ref))
    coltab(mosaiced) <- coltab(rast(ref))
  } 
  
  print("Saving")
  
  writeRaster(mosaiced, filename = save_path,
              datatype = dtype,
              filetype = "ENVI",
              overwrite = T,
              todisk = T,
              memfrac = 0.75)
  
  print("----------------------------")

  terra::tmpFiles(remove = T)
  
  print(Sys.time() - mosaic_start)
}
