vlce_df <- to_process %>%
  filter(var == "VLCE") %>%
  mutate(path_in = here::here("E:/", "VLCE2.0", "VLCE_HMM_1984-2024", paste0("UTM_", zone), paste0("LC_Class_HMM_", zone, "_", year, "_v20_v20.dat")),
         path_out = here::here(outpath, zone, paste0(var, "2.0"), paste0("LC_Class_HMM_", zone, "_", year, "_v20_v20.dat")))

attribution_df <- to_process %>%
  filter(var == "change_attribution") %>%
  distinct(var, zone) %>%
  mutate(path_in = here::here("L:/", "C2C_1984-2024", paste0("UTM_", zone), "Results", "Change_attribution", "Attribution_masked", paste0("Attribution_UTM", zone, "_v2_post.dat")),
         path_out = here::here(outpath, zone, var, paste0("Attribution_UTM", zone, "_v2.dat")))

metrics_df <- to_process %>%
  filter(var == "change_metrics") %>%
  distinct(var, zone) %>%
  mutate(path_in = list(here::here("L:/", "C2C_1984-2024", paste0("UTM_", zone), "Results", "Change_metrics") %>%
                          list.files(full.names = T, pattern = ".dat$"))) %>%
  unnest(path_in) %>%
  mutate(path_out = str_split(path_in, "/")) %>%
  unnest(path_out) %>%
  filter(str_detect(path_out, ".dat")) %>%
  mutate(path_out = here::here(outpath, zone, var, path_out)) %>%
  filter(str_detect(path_in, paste0("_", zone))) %>%
  distinct(path_in, .keep_all = T)

gcy_df <- to_process %>%
  filter(var == "gcy") %>%
  distinct(var, zone) %>%
  mutate(path_in = here::here("L:/", "C2C_1984-2024", paste0("UTM_", zone), "Results", "Change_metrics", paste0("SRef_", zone, "_Greatest_Change_Year.dat")),
         path_out = here::here(outpath, zone, var, paste0("SRef_UTM_", zone, "_GCY.dat")))

change_annual_df <- to_process %>%
  filter(var == "change_annual") %>%
  filter(year > 1984 & year < 2022) %>%
  mutate(path_in = here::here("L:/C2C_1984-2024", paste0("UTM_", zone), "Results", "Change_attribution", "change_attributed_annually_post_masked", paste0("SRef_UTM", zone, "_multiyear_attribution_", year, ".dat")),
         path_out = here::here(outpath, zone, var, paste0("SRef_UTM", zone, "_", year, "_change_annual.dat")))
        
proxies_df <- to_process %>% 
  filter(var == "proxies") %>% 
  mutate(
    path_in = if (is_multiple_year) {
      here::here("L:/", "C2C_1984-2024", paste0("UTM_", zone), "Results", "proxy_values_fitted", paste0("SRef_UTM", zone, "_", year, "_fitted_proxy_v2.dat"))
    } else {
      here::here("L:/", "C2C_1984-2024", paste0("UTM_", zone), "Results", "proxy_values", paste0("SRef_UTM", zone, "_", year, "_proxy_v2.dat"))
    },
    path_out = if (is_multiple_year) {
      file.path(here::here(outpath, zone, var, paste0("SRef_UTM", zone, "_", year, "_fitted_proxy_v2.dat")))
    } else {
      file.path(here::here(outpath, zone, var, paste0("SRef_UTM", zone, "_", year, "_proxy_v2.dat")))
    }
  )

structure_df <- to_process %>%
  filter(startsWith(var, "structure")) %>%
  mutate(var = gsub("structure_", "", var),
         path_in = here::here("E:/", "Forest_structure", paste0("UTM_", zone), var, paste0("UTM_", zone, "_", var, "_", year, ".dat")),
         path_out = here::here(outpath, zone, "structure", var, paste0("UTM_", zone, "_", var, "_", year, ".dat")))

topo_df <- to_process %>%
  filter(var == "topography") %>%
  distinct(var, zone) %>%
  mutate(path_in = list(here::here("G:/", "TopoData_v3") %>%
                          list.files(full.names = T, pattern = ".dat$", recursive = T))) %>%
  unnest(path_in) %>% 
  mutate(path_out = str_split(path_in, "/")) %>%
  unnest(path_out) %>%
  filter(str_detect(path_out, ".dat")) %>%
  mutate(path_out = here::here(outpath, zone, var, path_out)) %>%
  filter(str_detect(path_in, paste0("M", zone))) %>%
  distinct(path_in, .keep_all = T)

latlon_df <- to_process %>%
  filter(var == "lat" | var == "lon") %>%
  distinct(var, zone) %>%
  mutate(path_in = here::here("G:/", "ntems_lat-lon", var, paste0("UTM", zone, "_", var, ".dat")),
         path_out = here::here(outpath, zone, var, paste0("UTM", zone, "_", var, ".dat")))

climate_df <- to_process %>%
  filter(var == "climate") %>%
  distinct(climate = var, zone) %>%
  crossing(var = c("avgmaxt", "avgmint", "pcp")) %>%
  select(!climate) %>%
  mutate(path_in = here::here("G:/", "climate_layers_1km_corrected_spline", var, paste0("UTM", zone, "_", var, ".dat")),
         path_out = here::here(outpath, zone, var, paste0("UTM", zone, "_", var, ".dat")))

species_df <- to_process %>%
  filter(var == "species") %>%
  distinct(var, zone, year) %>%
  mutate(path_in = here::here("D:/", "Species_HMM_1984-2024", paste0("UTM_", zone), paste0("Species_classification_", zone, "_", year, "_1_leading_HMM.dat")),
         path_out = here::here(outpath, zone, var, paste0("Species_classification_", zone, "_", year, ".dat")))

age_df <- to_process %>%
  filter(var == "age") %>%
  distinct(var, zone) %>%
  mutate(path_in = here::here("E:/", "Age", "Age_2019_from_c2c1984-2021", "age", glue::glue("UTM{zone}_Forest_Age_2019.dat")),
         path_out = here::here(outpath, zone, var, glue::glue("Forest_Age_2019_{zone}.dat")))

fao_df <- to_process %>%
  filter(var == "fao") %>%
  distinct(var, zone, year) %>%
  mutate(path_in = here::here("E:/", "FAO_forest", 2023, glue::glue("UTM{zone}_Temporally_informed_forest_2023.dat")),
         path_out = here::here(outpath, zone, var, glue::glue("UTM{zone}_Temporally_informed_forest_2023.dat")))


process_df <- bind_rows(vlce_df,
                        proxies_df,
                        attribution_df,
                        metrics_df,
                        change_annual_df,
                        topo_df,
                        structure_df,
                        latlon_df,
                        climate_df,
                        species_df,
                        age_df,
                        gcy_df,
                        fao_df)

rm(vlce_df,
   proxies_df,
   attribution_df,
   metrics_df,
   change_annual_df,
   topo_df,
   structure_df,
   latlon_df,
   climate_df,
   species_df,
   age_df,
   gcy_df,
   fao_df)
