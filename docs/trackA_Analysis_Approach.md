
---

## 3) `docs/trackA_Analysis_Approach.md`

```md
# Track A: Analysis approach (template)

Track A implements a robustness-focused two-wave workflow for testing biomarker/feature–outcome coupling across a pre-specified feature set (e.g., multiple ROIs). The workflow is designed to be fully runnable on toy/simulated data and to support transparent reporting.

## Core ideas

1. **QC-safe two-wave construction**
   - Enforce exactly two waves per participant (T1 and T2).
   - Guard against duplicate ID×wave rows and join inflation.
   - Construct an explicit **age timeline** for interpretation:
     - `Age0` (baseline age)
     - `Age_TP` (age at assessment; `Age0 + followup_years × time_point`)
     - `Age_mid` (midpoint age; `Age0 + followup_years/2`)

2. **Within-person coupling via within/between decomposition**
   For each ROI/feature:
   - `ROI_pm`: participant mean across waves (between-person component)
   - `ROI_cwc`: deviation from participant mean (within-person component)

   Models are fit per ROI:
   - Base: `Y ~ time + group + Age0 + (1|ID)`
   - Coupling: add `ROI_cwc + ROI_pm`
   - Moderation: add `ROI_cwc × group` (plus `ROI_pm`)

3. **Multi-estimand change robustness**
   Change-score models are re-estimated under multiple estimands for both outcome and ROI:
   - Raw signed change: ΔX = X2 − X1
   - Percent change: %ΔX = 100 × (X2 − X1) / X1
   - Log ratio: log(X2 / X1)
   - Absolute magnitude: |ΔX| = |X2 − X1|

   A grid of models is run per ROI and estimand:
   - Coupling: `ΔY ~ ΔROI + Age0 + group`
   - Moderation: `ΔY ~ ΔROI × group + Age0`

4. **Multiple testing control (BH–FDR families)**
   BH–FDR correction is applied within pre-defined families aligned to hypothesis sets (e.g., coupling terms across ROIs; moderation terms across ROIs; estimand-specific families across ROIs).

5. **Targeted mediation (ACME/ADE; secondary)**
   The template includes targeted mediation analysis (ACME/ADE/total effects; `mediation` package) on change scores as a secondary analysis, implemented consistently across ROIs and estimands when desired.

## Outputs
Track A writes outputs to `outputs/trackA_multiROI/` when rendered. Outputs are not committed to the repository.
