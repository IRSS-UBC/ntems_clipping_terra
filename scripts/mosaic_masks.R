masks_path <- "\\\\FRst-frm-2232b\\G$\\valid_zero_harmonized_LCC"
# location of masks

masks_files <- list.files(masks_path) 

masks_files <- masks_files[endsWith(masks_files, ".dat")] %>%
  here::here(masks_path, .)

shp_path <- "\\\\FRst-frm-2232b\\G$\\non_overlapping_polygon"

shp_files <- list.files(shp_path)

shp_files <- shp_files[endsWith(shp_files, ".shp")] %>%
  here::here(shp_path, .)

# get only shapefiles to iterate over
if (!file.exists(here::here("shapefiles", "non_overlapping_masks_canada.shp"))) {

  read_add_crs <- function(shp_path) {
    # pulls the ntems zone form name and appends it so when the intersection 
    # happens it can figure out the zones to process
    shp <- shp_path %>%
      read_sf()
    
    zone <- tools::file_path_sans_ext(basename(shp_path)) %>%
      str_extract("\\d.*") #anything after first digit
    
    shp %>%
      mutate(crs = zone)
  } 
  
  map(shp_files, read_add_crs) %>%
    map(st_transform, crs = 3347) %>%
    bind_rows() %>%
    st_write(here::here("shapefiles", "non_overlapping_masks_canada.shp"), append = F)
  rm(read_add_crs)
  
}

nom_cad <- read_sf(here::here("shapefiles", "non_overlapping_masks_canada.shp"))

## make clean polygon masks


mask_rcl <- matrix(c(0, 1,
                     NA, 1),
                   ncol = 2)


mask_save_base <- map(masks_files, tools::file_path_sans_ext) %>%
  map(basename) %>%
  unlist() 

mask_save_names <- here::here("shapefiles", paste0(mask_save_base, ".shp"))

if(!all(file.exists(mask_save_names))) {
  clean_masks <- map(masks_files, rast) %>%
    map(classify, rcl = mask_rcl) %>%
    map(as.polygons) %>%
    map2(.x = ., .y = mask_save_names, .f = writeVector)
}


