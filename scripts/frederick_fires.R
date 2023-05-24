library(tidyverse)
library(sf)

zones <- c(7:11)
years <- c(1985:2020)

fun_df <- crossing(zones, years)

zones_iter <- fun_df %>%
  pull(zones)

years_iter <- fun_df %>%
  pull(years)

load_sfs <- function(zone, year) {
  filename <-
    paste0("Logic_Rules_Change_Attribution_UTM_",
           zone,
           "S_",
           year,
           ".shp")
  sf <-
    st_read(
      here::here(
        "N:/",
        paste0("UTM_", zone, "S"),
        "Results",
        "Change_attribution",
        "Changes_attributed_logic_rules",
        filename
      )
    )
  
  clean_sf <- sf %>%
    filter(GIVEN_CLASS == "Fire") %>%
    select(GIVEN_CLASS, geometry) %>%
    mutate(zone = paste0(zone, "S"),
           year = year)
}

output <- map2(.x = zones_iter, .y = years_iter, .f = load_sfs) %>%
  map(st_transform, crs = 3978) %>%
  bind_rows() %>%
  st_intersection(bcmaps::bc_bound())

write_sf(output,
         here::here("Z:/",
                    "ByUser",
                    "Muise",
                    "frederick_fires.shp"))


