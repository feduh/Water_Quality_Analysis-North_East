# importing libraries
library(dplyr)
library(ggplot2)
library(readr) # useful to read csv files

# reading csv files
water_quality_2023 <- read_csv("data/WaterQuality23.csv")
water_quality_2024 <- read_csv("data/WaterQuality24.csv")
water_quality_2025 <- read_csv("data/WaterQuality25.csv")
