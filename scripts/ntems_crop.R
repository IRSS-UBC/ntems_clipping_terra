# crops ntems layers based on in and out paths
# can be used with map2 to functionally program

ntems_crop <- function(path_in, path_out) {
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
    mask(my_aoi)
  
  if(str_detect(path_in, "structure")) {
    print("structure raster, masking based on the VLCE raster")
    
    structure_info <- tools::file_path_sans_ext(basename(path_in))
    
    year <- str_extract(structure_info, "[0-9]{4}")
    zone <- str_extract(structure_info, "[0-9]{1,2}[a-zA-Z]{1}")
    
    vlce_mask <- here::here(outpath, zone, "VLCE2.0", paste0("LC_Class_HMM_", zone, "_", year, "_v20_v20.dat"))
    
    vlce_mask <- rast(vlce_mask)
    vlce_mask <- vlce_mask %in% c(81, 210, 220, 230)
    vlce_mask[vlce_mask == 0] <- NA
    
    save_rast <- mask(save_rast, vlce_mask)
  }
  
  writeRaster(save_rast, filename = path_out,
              datatype = get_data_type(path_in),
              filetype = "ENVI",
              overwrite = T)
  print(Sys.time() - crop_start)
  
}


