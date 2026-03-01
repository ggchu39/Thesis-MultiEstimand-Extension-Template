# Thesis-MultiEstimand-Extension-Template


## How to run

This repository is a **public template**. It runs end-to-end on **toy/simulated data only**.

### Prerequisites
- R (recommended: recent version)
- Quarto installed (desktop app)
- R packages used in the template (install on demand, or use `renv` if you add it)

### Track B: Single-feature/ROI focused workflow
Runs a two-wave pipeline:
1) QC-safe dataset build (two waves per participant)  
2) Descriptive trajectory (spaghetti + GAM smooth over age-at-assessment)  
3) LME inference (Age0 × Time, optional group terms) + ΔΔ change-link to outcome  

**Run:**
- Render `analysis/trackB_singleROI/00_run_all.qmd`

**Outputs:**
- Written to `outputs/trackB_singleROI/`

### Track A: Multi-feature/ROI + multi-estimand robustness (coming next)
This track will cover:
- Multi-feature within-person coupling (LME cwc/pm) across a pre-specified feature set
- Change-score robustness across multiple estimands (raw, percent, log ratio, absolute magnitude)
- BH–FDR correction within pre-defined hypothesis families
- Optional descriptive decomposition (non-causal)

**Run (once added):**
- Render `analysis/trackA_multiROI/00_run_all.qmd`

**Outputs (once added):**
- Written to `outputs/trackA_multiROI/`

### If Quarto rendering fails
- Ensure Quarto is installed and available on your system.
- Alternatively, render the `.qmd` files manually in numeric order within each track folder.







