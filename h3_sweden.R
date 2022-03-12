library(dplyr)
library(h3jsr)
library(giscoR)
library(sf)

borders <- gisco_get_countries() %>% 
  filter(NAME_ENGL == "Sweden")

h3_polygons_list <- polyfill(
  borders, 
  res = 3, 
  simple = T)

h3_polygons <- st_sfc(crs = 4326)
for (i in 1:length(h3_polygons_list$`0`)){
  pt <- h3_to_polygon(h3_polygons_list$`0`[[i]])
  pt <- st_sf(pt)
  pt$id <- h3_polygons_list$`0`[[i]]
  h3_polygons <- rbind(h3_polygons, pt)
}

mapview::mapview(h3_polygons)