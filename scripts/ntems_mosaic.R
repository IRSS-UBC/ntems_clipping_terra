# mosaic clipped ntems rasters together
# first must use the utm masks

ntems_mosaicer <- function(tibble, overwrite = F) {
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
  
  if(!overwrite & file.exists(save_path)) {
    print("Don't overwrite, and file already exists")
    return()
  }
  
  
  message()
  print(paste("save path:", save_path))
  print("mosaicing ------------------")
  print(paste("zones:", toString(utmzone_all)))
  print(paste("year:", year))
  print(paste("variable:", var))
  
  
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
         align = T, method = "near", gdal = T, by_util = T, threads = T, .progress = "Projection")
  
  print("Masking")
  
  masked_data <- proj_rasts %>%
    map2(.x = ., .y = utm_masks_proj, .f = mask,
         todisk = T, .progress = "Masking")
  
  print("Mosaicing")
  
  mosaiced <- masked_data %>%
    sprc() %>%
    mosaic(fun = "max") %>%
    crop(aoi, mask = T, touches = T)

  print("Mosaiced")
    
  if (var == "VLCE" | var == "change_attribution" | var == "change_annual" | var == "species") {
    
    # implement a direct header modification here
    print("Adding levels and colours")
    
    rastref <- rast(ref)
    
    levels(mosaiced) <- levels(rastref)
    coltab(mosaiced) <- coltab(rastref)[[1]]
  } 
  
  print("Saving")
  
  writeRaster(mosaiced, filename = save_path,
              datatype = dtype,
              filetype = "ENVI",
              overwrite = T,
              todisk = T,
              memfrac = 0.90)
  
  print("----------------------------")

  terra::tmpFiles(remove = T)
  
  print(Sys.time() - mosaic_start)
}
