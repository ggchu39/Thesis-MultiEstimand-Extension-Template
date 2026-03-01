# Track B: Single-feature/ROI workflow (template)

Track B mirrors a common “single ROI” longitudinal request: describe the ROI trajectory over age and test whether ROI change relates to outcome change in a two-wave dataset.

## Steps

1. **QC-safe two-wave construction**
   - Enforce exactly two waves per participant (T1/T2).
   - Create derived time variables and an age-at-assessment axis (Age0 + follow-up).

2. **Trajectory visualisation**
   - Spaghetti plot (two-wave lines per participant).
   - GAM smooth over age-at-assessment (optionally stratified by group).

3. **Inference (LME) and change–change link**
   - LME for ROI with `Age0 × Time` (and optional group terms).
   - Wide-format change-score regression linking ΔROI to ΔOutcome:
     - `ΔY ~ ΔROI + Age0 + group`
     - optional `ΔROI × group`

## Outputs
Track B writes outputs to `outputs/trackB_singleROI/` when rendered. Outputs are not committed to the repository.
