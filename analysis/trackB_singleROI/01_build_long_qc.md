---
title: "Track B (single-ROI): Build QC-safe two-wave dataset"
format: html
execute:
  echo: true
  warning: false
  message: false
---

## Purpose
This step creates a QC-safe, two-wave long dataset for **single-feature/ROI** analyses.

It:
- loads **toy** two-wave data,
- derives time variables (including age-at-assessment),
- splits into two analysis streams:
  - **Stream A (feature-only)**: trajectory models (does NOT require outcome Y)
  - **Stream B (feature+outcome)**: coupling/change-score models (requires outcome Y)
- drops missingness *per stream*,
- collapses duplicates within ID×wave (if any),
- enforces exactly 2 waves per ID,
- centers baseline age within the final analysis sample per stream.

```{r}
library(dplyr)
library(tidyr)
library(readr)
library(here)

source(here::here("R", "simulate_toy_data.R"))
source(here::here("R", "qc_two_wave_long.R"))

# Output folder (repo-safe)
out_dir <- here::here("outputs", "trackB_singleROI")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ---- 1) Load toy data ----
# Toy long data should contain: ID, wave, Age0, Sex, Y, ROI_L, ROI_R
df_long <- simulate_toy_two_wave_long(n_id = 120, followup_years = 4)

# ---- 2) Build QC-safe streams ----
qc <- build_qc_two_wave_streams(
  df_long = df_long,
  id_col = "ID",
  wave_col = "wave",
  wave_map = c("T1" = 0L, "T2" = 1L),  # adjust if your toy data uses different labels
  baseline_age_col = "Age0",
  sex_col = "Sex",
  outcome_col = "Y",
  roi_left_col = "ROI_L",
  roi_right_col = "ROI_R",
  followup_years = 4,
  collapse_duplicates = TRUE
)

dat_roi_only <- qc$dat_roi_only   # Stream A: ROI trajectory (no Y required)
dat_roi_y    <- qc$dat_roi_y      # Stream B: ROI + Y analyses

# ---- 3) Save for next steps ----
saveRDS(dat_roi_only, file = file.path(out_dir, "dat_roi_only_long_2waves.rds"))
saveRDS(dat_roi_y,    file = file.path(out_dir, "dat_roi_y_long_2waves.rds"))


# Sanity check prints
qc$qc_summary
