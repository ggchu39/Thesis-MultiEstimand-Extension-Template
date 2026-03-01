<img width="854" height="733" alt="image" src="https://github.com/user-attachments/assets/11046809-8d65-4748-a934-7ae7ede973a9" />

# Thesis-MultiEstimand-Extension-Template
This repository is a **public template** that extends my 2024 MSc thesis workflow with a robustness-focused two-wave pipeline. The emphasis is on verifying that any biomarker–outcome coupling signals are not artifacts of a single change definition or model specification, and on visualising whether change patterns depend on baseline age (age timeline). The template uses **toy/simulated data only** and includes no real datasets or results.

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

### Track A: Multi-feature/ROI + multi-estimand robustness 
This track covers:
- Multi-feature within-person coupling (LME cwc/pm) across a pre-specified feature set
- Change-score robustness across multiple estimands (raw, percent, log ratio, absolute magnitude)
- BH–FDR correction within pre-defined hypothesis families
- Targeted mediation analysis (ACME/ADE; secondary)

**Run:**
- Render `analysis/trackA_multiROI/00_run_all.qmd`

**Outputs:**
- Written to `outputs/trackA_multiROI/`
### If Quarto rendering fails
- Ensure Quarto is installed and available on your system.
- Alternatively, render the `.qmd` files manually in numeric order within each track folder.

### Mediation (ACME/ADE) in this template

This template implements **targeted mediation analysis** (ACME/ADE/total effects; `mediation` package) in a two-wave change-score setting. It extends a core mediation workflow by incorporating baseline-age adjustment, multi-estimand change definitions (raw Δ, %Δ, log-ratio, |Δ|), and BH–FDR correction within pre-defined hypothesis families to support robustness-focused reporting.

## Repository layout
- `analysis/` Quarto workflows (Track A and Track B)
- `R/` reusable helper functions
- `docs/` short methodological notes and templates
- `outputs/` created when you run the workflows (not committed)
- `docs/` includes the Track A RQs/Hypotheses template and short workflow notes

