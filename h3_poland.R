library(dplyr)
library(h3jsr)
library(giscoR)
library(sf)
library(tmap)
library(viridis)
library(openxlsx)

borders <- gisco_get_countries() %>% 
  filter(NAME_ENGL == "Poland")

h3_polygons_list <- polyfill(
  borders, 
  res = 4, # https://h3geo.org/docs/core-library/restable/
  simple = T)

h3_polygons <- st_sfc(crs = 4326)
for (i in 1:length(h3_polygons_list$`0`)){
  pt <- h3_to_polygon(h3_polygons_list$`0`[[i]])
  pt <- st_sf(pt)
  pt$id <- h3_polygons_list$`0`[[i]]
  h3_polygons <- rbind(h3_polygons, pt)
}

# mapview::mapview(h3_polygons)

# https://www.eea.europa.eu/data-and-maps/data/bathing-water-directive-status-of-bathing-water-13

pl <- read.xlsx("data/PL_BW2020.xlsx", 2) %>% 
  st_as_sf(., coords = c("lon", "lat"), crs = 4326)

pl <- st_join(pl, h3_polygons)

number_baths_per_h3 <- pl %>%
  group_by(id) %>% 
  summarise(n = n()) %>% 
  st_drop_geometry() %>% 
  ungroup()

h3_polygons <- left_join(h3_polygons, number_baths_per_h3, by = "id")

tm_shape(h3_polygons) + 
  tm_fill("n", style = "jenks", palette = "viridis", alpha = 0.7) +
  tm_borders()