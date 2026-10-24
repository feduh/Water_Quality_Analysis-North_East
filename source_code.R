# extended comments and explanations are on the Quarto document.

# loading tidyverse packages for data manipulation, visualization, and parsing
library(dplyr)
library(ggplot2)
library(readr)
library(lubridate)

# loading raw Environment Agency water quality datasets (2023 - 2025)
water_quality_2023 = read_csv("data/WaterQuality23.csv")
water_quality_2024 = read_csv("data/WaterQuality24.csv")
water_quality_2025 = read_csv("data/WaterQuality25.csv")

# unifying tables so filters can manage all tables, avoiding errors.
tables = bind_rows(water_quality_2023,water_quality_2024,water_quality_2025)

# extracting lead records in surface river waters across Tyne, Wear, and Tees.
lead_table = filter(
  tables,
  (`determinand.prefLabel` == "Lead, Dissolved" | `determinand.prefLabel` == "Lead : BLM Bioavailable"),
  (`samplingPoint.subArea` == "WEAR & TEES" | `samplingPoint.subArea` == "NORTHUMBERLAND & TYNE"),
  `samplingPoint.samplingPointType` == "FRESHWATER - RIVERS",
  sampleMaterialType == "RIVER / RUNNING SURFACE WATER",
  unit == "MICROGRAM PER LITRE")

# selecting and renaming core spatial, temporal, and monitoring attributes.
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

# parsing temporal features, converting numerical concentrations, flagging under limits ("<") samples.
lead_table = mutate(
  lead_table,
  date = as_date(date),
  year = year(date),
  under_limits = startsWith(result, "<"),
  result = parse_number(result))

# acute risk: calculates annual maximum dissolved lead concentrations per site,
# that will be compared to the MAC-EQS threshold (14 µg/L) to detect peak events.
acute_risk_table = filter(
  lead_table,
  lead_type == "Lead, Dissolved") |>
  group_by(id, latitude, longitude, year) |>
  summarise(max_result = max(result, na.rm = TRUE), n_lead_dissolved = n(), .groups = "drop")

# chronic risk: calculates annual mean bioavailable lead (BLM-adjusted) per site,
# that will be compared to the AA-EQS threshold (1.2 µg/L) to monitor long-term baseline exposure for aquatic life.
chronic_risk_table = filter(
  lead_table,
  lead_type == "Lead : BLM Bioavailable") |>
  group_by(id, latitude, longitude, year) |>
  summarise(avg_result = mean(result, na.rm = TRUE), n_lead_bioavailable = n(), .groups = "drop")

# combining acute and chronic assessments through full_join to obtain all monitoring sites;
# this prevents data loss where stations monitor only dissolved lead or BLM bioavailability.
risk_table = acute_risk_table |>
  full_join(chronic_risk_table, by = c("id", "year", "latitude", "longitude"))

