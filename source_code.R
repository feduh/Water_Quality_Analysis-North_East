# extended comments and explanations are on the Quarto document.

# loading tidyverse packages for data manipulation, visualization, and parsing
library(dplyr)
library(ggplot2)
library(readr)

# loading raw Environment Agency water quality datasets (2023 - 2025)
water_quality_2023 = read_csv("data/WaterQuality23.csv")
water_quality_2024 = read_csv("data/WaterQuality24.csv")
water_quality_2025 = read_csv("data/WaterQuality25.csv")

# unifying tables so filters can manage all tables, avoiding errors.
tables = bind_rows(water_quality_2023,water_quality_2024,water_quality_2025)

# extracting lead records in surface river waters across Tyne, Wear, and Tees.
lead_table = filter(tables,
  (`determinand.prefLabel` == "Lead, Dissolved" | `determinand.prefLabel` == "Lead : BLM Bioavailable"),
  (`samplingPoint.subArea` == "WEAR & TEES" | `samplingPoint.subArea` == "NORTHUMBERLAND & TYNE"),
  `samplingPoint.samplingPointType` == "FRESHWATER - RIVERS",
  sampleMaterialType == "RIVER / RUNNING SURFACE WATER",
  unit == "MICROGRAM PER LITRE")
