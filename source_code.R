# Extended comments and explanations are on the Quarto document.

# Loading tidyverse packages for data manipulation and visualization, 
# and spatial packages (sf, rnaturalearth, rnaturalearthhires) to build the base map.
library(dplyr)
library(ggplot2)
library(readr)
library(lubridate)

library(sf)
library(rnaturalearth)
library(rnaturalearthhires)

# Loading raw Environment Agency water quality datasets (2023 - 2025).
water_quality_2023 = read_csv("data/WaterQuality23.csv")
water_quality_2024 = read_csv("data/WaterQuality24.csv")
water_quality_2025 = read_csv("data/WaterQuality25.csv")

# Unifying the three annual tables into one data frame so filters can be applied
# once across all years, avoiding code repetition.
tables = bind_rows(water_quality_2023,water_quality_2024,water_quality_2025)

# Extracting dissolved and bioavailable lead records in running surface river waters
# (in µg/L) across Northumberland & Tyne and Wear & Tees sub-areas.
lead_table = filter(
  tables,
  (`determinand.prefLabel` == "Lead, Dissolved" | `determinand.prefLabel` == "Lead : BLM Bioavailable"),
  (`samplingPoint.subArea` == "NORTHUMBERLAND & TYNE" | `samplingPoint.subArea` == "WEAR & TEES"),
  `samplingPoint.samplingPointType` == "FRESHWATER - RIVERS",
  sampleMaterialType == "RIVER / RUNNING SURFACE WATER",
  unit == "MICROGRAM PER LITRE")

# Selecting and renaming core spatial, temporal, and monitoring attributes.
lead_table = select(
  lead_table,
  id = `samplingPoint.notation`,
  longitude = `samplingPoint.longitude`,
  latitude = `samplingPoint.latitude`,
  sub_area = `samplingPoint.subArea`,
  point_type = `samplingPoint.samplingPointType`,
  date = `phenomenonTime`,
  lead_type = `determinand.prefLabel`,
  material_type = sampleMaterialType,
  result)

# Parsing dates and years, flagging samples below the limit of detection ("<"),
# and converting text concentrations into numeric values.
lead_table = mutate(
  lead_table,
  date = as_date(date),
  year = year(date),
  below_limit_detection = startsWith(result, "<"),
  result = parse_number(result))

# Acute risk: calculates annual maximum dissolved lead concentrations per site,
# that will be compared to the MAC-EQS threshold (14 µg/L) to detect peak events.
acute_risk_table = filter(
  lead_table,
  lead_type == "Lead, Dissolved") |>
  group_by(id, latitude, longitude, year) |>
  summarise(max_result = max(result, na.rm = TRUE), n_lead_dissolved = n(), .groups = "drop")

# Chronic risk: calculates annual mean bioavailable lead (BLM-adjusted) per site,
# that will be compared to the AA-EQS threshold (1.2 µg/L) to monitor long-term baseline exposure for aquatic life.
chronic_risk_table = filter(
  lead_table,
  lead_type == "Lead : BLM Bioavailable") |>
  group_by(id, latitude, longitude, year) |>
  summarise(avg_result = mean(result, na.rm = TRUE), n_lead_bioavailable = n(), .groups = "drop")

# Combining acute and chronic assessments through full_join to obtain all monitoring sites;
# this prevents data loss where stations monitor only dissolved lead or BLM bioavailability.
risk_table = acute_risk_table |>
  full_join(chronic_risk_table, by = c("id", "year", "latitude", "longitude"))

# Defining risk status levels to fix categories and legend order for both maps,
# even when a category is missing from the data.
risk_status = c("No Data", "Below EQS", "Above EQS")

# Defining acute table which will be used for the map,
# to label different statuses based on MAC-EQS threshold (14 µg/L).
acute_map = mutate(risk_table,
                   status = case_when(is.na(max_result) ~ "No Data",
                                      max_result <= 14 ~ "Below EQS",
                                      .default = "Above EQS"),
                   status = factor(status,
                                   levels = risk_status)) |>
  arrange(status) # Ordering monitoring points by risk severity (status) to ensure high-risk sites ("Above EQS") are plotted on top of lower-risk points.

# Defining chronic table which will be used for the map,
# to label different statuses based on AA-EQS threshold (1.2 µg/L).
chronic_map = mutate(risk_table,
                     status = case_when(is.na(avg_result) ~ "No Data", 
                                        avg_result <= 1.2 ~ "Below EQS", 
                                        .default = "Above EQS"),
                     status = factor(status,
                                     levels = risk_status)) |>
  arrange(status) # Ordering monitoring points by risk severity (status) to ensure high-risk sites ("Above EQS") are plotted on top of lower-risk points.

# Retrieving UK internal administrative boundaries (counties/unitary authorities)
# as an sf object to provide local geographic context and coastline detail.
uk_map = ne_states(country = "united kingdom", returnclass = "sf")

# Computing coordinate ranges from monitoring sites to zoom on the study area.
lon_limits = range(risk_table$longitude)
lat_limits = range(risk_table$latitude)

# Plotting acute risk map.
ggplot() +
  geom_sf(data = uk_map, fill = "white", col = "#B0B0B0") +
  geom_point(data = acute_map, 
             aes(x = longitude, y = latitude, col = status, size = status), 
             alpha = 0.7,
             show.legend = TRUE) + # "No Data" is not present in this map, but it is in the legend.
  facet_wrap(~ year) +
  coord_sf(xlim = lon_limits, ylim = lat_limits) +
  labs(title = "Classification of maximum dissolved lead (14 µg/L) per site",
       x = "Longitude",
       y = "Latitude") +
  scale_colour_manual(name = "MAC-EQS threshold", 
                      values = c("No Data" = "#808080",
                                 "Below EQS" = "#2C6FBB",
                                 "Above EQS" = "#8E1B3A"), drop = FALSE) +
  scale_size_manual(name = "MAC-EQS threshold", 
                    values = c("No Data"   = 2.0,
                               "Below EQS" = 2.5,
                               "Above EQS" = 3.5), drop = FALSE) +
  theme(
    panel.background = element_rect(fill = "#D6EAF8"),
    panel.border = element_rect(fill = NA, colour = "black"),
    strip.background = element_rect(fill = "#EC9CB2", colour = "black"),
    legend.key = element_blank())

# Plotting chronic risk map.
ggplot() +
  geom_sf(data = uk_map, fill = "white", col = "#B0B0B0") +
  geom_point(data = chronic_map, 
             aes(x = longitude, y = latitude, col = status, size = status), 
             alpha = 0.7) +
  facet_wrap(~ year) +
  coord_sf(xlim = lon_limits, ylim = lat_limits) +
  labs(title = "Classification of mean bioavailable lead (1.2 µg/L) per site",
       x = "Longitude",
       y = "Latitude") +
  scale_colour_manual(name = "AA-EQS threshold", 
                      values = c("No Data" = "#808080",
                                 "Below EQS" = "#2C6FBB",
                                 "Above EQS" = "#E07B00"), drop = FALSE) +
  scale_size_manual(name = "AA-EQS threshold", 
                    values = c("No Data"   = 2.0,
                               "Below EQS" = 2.5,
                               "Above EQS" = 3.5), drop = FALSE) +
  theme(
    panel.background = element_rect(fill = "#D6EAF8"),
    panel.border = element_rect(fill = NA, colour = "black"),
    strip.background = element_rect(fill = "#FFCA8A", colour = "black"),
    legend.key = element_blank())
