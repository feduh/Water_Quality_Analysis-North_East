# Visual Exploration of River Lead Concentrations in North East England (2023–2025)

**Author:** Federica Gaglianone (SN: 260405733)

## Project Overview

This repository contains the R code and Quarto report for a visual data analysis project developed for the **Water and Abandoned Metal Mines (WAMM)** programme. 

The project investigates the following research question:
> *"How does the spatial and temporal distribution of river lead concentrations, evaluated against acute and chronic EQS thresholds, vary in the 'Northumberland & Tyne' and 'Wear & Tees' sub-areas between 2023 and 2025?"*

Using official water quality monitoring records, the analysis evaluates river lead concentrations against the UK Environmental Quality Standards (EQS):
- **Acute risk (MAC-EQS):** Annual maximum concentration of `"Lead, Dissolved"` compared against the **14 µg/L** threshold.
- **Chronic risk (AA-EQS):** Annual mean concentration of `"Lead : BLM Bioavailable"` compared against the **1.2 µg/L** threshold for inland surface waters.

---

## Repository Structure

- `Water_Quality_Analysis.qmd`: The main Quarto document containing the complete CRISP-DM report (Business Understanding, Data Understanding, Data Preparation, Modelling and Analysis, Evaluation, and Deployment), quality check tables, and faceted maps.
- `source_code.R`: The standalone R script containing the data preparation, aggregation, and `ggplot2` mapping pipeline.
- `.gitignore`: Configured to exclude the `data/` folder and large raw CSV files from version control.
- `README.md`: Project documentation and instructions for reproducing the analysis.

---

## Data Instructions and Version Disclaimer

Because the three raw CSV files are large (approximately 55–60 MB each), they are excluded from this repository via `.gitignore` to keep the Git history lightweight and because only the code is distributed here.

To run the code and render the Quarto report locally, you need to download the data and place them in a folder named `data/` inside the root directory of this project:

1. Create a folder named **`data`** in the main project directory.
2. Download the North East England water quality datasets for **2023, 2024, and 2025** from the Defra & Environment Agency [Water Quality Archive](https://environment.data.gov.uk/water-quality/view/landing) (published under the Open Government Licence v3.0).
3. Save and name the three files inside the `data/` folder exactly as follows:
   - `data/WaterQuality23.csv`
   - `data/WaterQuality24.csv`
   - `data/WaterQuality25.csv`

**Note on Data Version (22 October 2026):**  
All results, tables, and maps in this project are based on the version of the datasets downloaded on **22 October 2026**. If the Environment Agency updates, adds, or modifies records in the archive after this date, running the code on newer downloads may produce different numbers or map patterns. I am not responsible for changes resulting from future updates to the external database.

---

## Required R Packages and How to Run

To reproduce the analysis, make sure you have **R**, **RStudio**, and **Quarto** installed, along with the following R packages:

```r
install.packages(c(
  "dplyr",
  "ggplot2",
  "readr",
  "lubridate",
  "sf",
  "rnaturalearth"
))

# rnaturalearthhires is required by ne_states() for high-resolution UK boundaries:
install.packages(
  "rnaturalearthhires",
  repos = "[https://ropensci.r-universe.dev](https://ropensci.r-universe.dev)",
  type = "source"
)
```

Once the data/ folder is set up with the three CSV files:

Open source_code.R in RStudio to run the script step by step, or open Water_Quality_Analysis.qmd and click Render to generate the full HTML report.
