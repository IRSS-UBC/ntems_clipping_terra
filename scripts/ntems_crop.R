# crops ntems layers based on in and out paths
# can be used with map2 to functionally program

ntems_crop <- function(path_in, path_out, overwrite = F) {
  
  if(!overwrite & file.exists(path_out)) {
    print("Don't overwrite, and file already exists")
    return()
  }
  
  
  crop_start <- Sys.time()
  print(paste("Processing input file of:", path_in))
  
  if (!dir.exists(dirname(path_out))) {
    dir.create(dirname(path_out), recursive = T)
  }
  
  my_rast <- rast(path_in)
  
  my_aoi <- vect(aoi) %>%
    project(my_rast) #%>%
  # ext()
  
  save_rast <- crop(my_rast, my_aoi) %>%
    mask(my_aoi) %>% trim()
  
  if(str_detect(path_in, "VLCE")) {
    save_rast <- save_rast %>% 
      subst("Unclassified", NA)
  }
  
  if (str_detect(path_in, "structure")) {
    print("structure raster, masking based on the VLCE raster")
    
    structure_info <- tools::file_path_sans_ext(basename(path_in))
    
    year <- str_extract(structure_info, "[0-9]{4}")
    zone <- str_extract(structure_info, "[0-9]{1,2}[a-zA-Z]{1}")
    
    vlce_mask <-
      here::here(
        outpath,
        zone,
        "VLCE2.0",
        paste0("LC_Class_HMM_", zone, "_", year, "_v20_v20.dat")
      )
    
    vlce_mask <- rast(vlce_mask)
    vlce_mask <- vlce_mask %in% c(81, 210, 220, 230)
    vlce_mask[vlce_mask == 0] <- NA
    
    save_rast <- mask(save_rast, vlce_mask)
  }
  
  if (str_detect(path_in, "Forest_Age")) {
    save_rast <- 2019 - save_rast
    masklyr <- save_rast > 150
    save_rast <-
      mask(save_rast,
           masklyr,
           maskvalues = 1,
           updatevalue = 151)
  }
  
  if (endsWith(path_in, ".dat")) {
    writeRaster(
      save_rast,
      filename = path_out,
      datatype = get_data_type(path_in),
      filetype = "ENVI",
      overwrite = T
    )
  } else {
    writeRaster(
      save_rast,
      filename = path_out,
      #datatype = get_data_type(path_in),
      filetype = "ENVI",
      overwrite = T
    )
  }
  print(Sys.time() - crop_start)
  
}
