source(here::here("scripts", "mosaic_masks.R"))

utmzone_all <- st_intersection(aoi %>% st_zm() %>% st_transform(3347) %>% st_make_valid, nom_cad %>% st_make_valid()) %>%
  pull(crs) %>%
  unique() # solves multipart polygon issues

valid_zones <- list.files("\\\\FRst-frm-2232b\\E$\\VLCE2.0\\VLCE_HMM_1984-2022") %>%
  str_split("_") %>%
  sapply("[", 2)

utmzone_all <- utmzone_all[utmzone_all %in% valid_zones]
  

if(length(utmzone_all > 1)) {
  out_crs = crs(rast(template))
}

# add the m in front so it only detects those it should
# without it, 9S would also detect 19S
utm_masks <- str_subset(mask_save_names, paste(paste0("M", utmzone_all), collapse = "|")) %>%
  map(vect)

names(utm_masks) <- utmzone_all
