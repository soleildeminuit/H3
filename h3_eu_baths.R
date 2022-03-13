library(dplyr)
library(h3jsr)
library(giscoR)
library(sf)
library(tmap)
library(viridis)
library(openxlsx)
library(hablar)

# https://www.eea.europa.eu/data-and-maps/data/bathing-water-directive-status-of-bathing-water-13
excels <- dir(paste(getwd(), "/data", sep=""), "*.xlsx")

i <- 1
l <- list()
df <- data.frame()
for (excel in excels) {
  f <- paste(getwd(), "/data/",excel, sep = "")
  print(f)
  x <- openxlsx::read.xlsx(f, 2)
  l[[i]] <- x
  i <- i+1
}
df <- do.call("rbind", l)

df <- hablar::retype(df)

df <- df %>%
  st_as_sf(., coords = c("lon", "lat"), crs = 4326)

# saveRDS(df, "data/baths.rds")

borders <- gisco_get_countries()
borders <- st_crop(borders, xmin = -26, xmax = 45,
                          ymin = 30, ymax = 73)
borders <- borders %>% st_union()

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

# st_write(h3_polygons, "data/h3_polygons_eu.geojson")
# saveRDS(h3_polygons, "data/h3_polygons.rds")
# mapview::mapview(h3_polygons)

df <- st_join(df, h3_polygons)

number_baths_per_h3 <- df %>%
  st_drop_geometry() %>% 
  group_by(id) %>% 
  summarise(n = n()) %>% 
  ungroup()

h3_polygons <- left_join(h3_polygons, number_baths_per_h3, by = "id")

tm_shape(h3_polygons) + 
  tm_fill("n", style = "quantile", palette = "viridis", alpha = 0.7) +
  tm_borders()