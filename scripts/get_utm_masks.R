source(here::here("scripts", "mosaic_masks.R"))

# aoi_transformed <- aoi %>% st_transform(3978) %>% st_make_valid
nom_cad_transformed <- nom_cad %>% st_transform(3978) %>% st_make_valid()

# print(st_crs(aoi))
# print(st_crs(nom_cad_transformed))

intersection <- st_intersection(aoi, nom_cad_transformed)

# Extract and find unique 'crs' values
utmzone_all <- intersection %>% pull(crs) %>% unique()
utmzone_all <- sub("_vld_ext", "", utmzone_all)
print(paste0("utmzone_all: ", utmzone_all))

valid_zones <- list.files("U:\\VLCE2.0_1984-2021") %>%
  str_split("_") %>%
  sapply("[", 2)

utmzone_all <- utmzone_all[utmzone_all %in% valid_zones]
  
print(paste0("AOI is located in ", length(utmzone_all), " UTM zones: "))
print(utmzone_all)
print("Note that letters N or S correspond to the internal NTEMS data division, not northern or southern hemishphere")

if(length(utmzone_all > 1)) {
  out_crs = crs(rast(template))
}

# add the m in front so it only detects those it should
# without it, 9S would also detect 19S
utm_masks <- str_subset(mask_save_names, paste(paste0("M", utmzone_all), collapse = "|")) %>%
  map(vect)

names(utm_masks) <- utmzone_all
