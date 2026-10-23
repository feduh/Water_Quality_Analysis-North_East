# extended comments and explanations are on the Quarto document.

# loading tidyverse packages for data manipulation, visualization, and parsing.
library(dplyr)
library(ggplot2)
library(readr)
library(lubridate)

# loading raw Environment Agency water quality datasets (2023 - 2025).
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
