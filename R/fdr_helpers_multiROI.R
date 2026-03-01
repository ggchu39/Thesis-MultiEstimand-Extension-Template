
---

# 2) Add helper `R/fdr_helpers_multiROI.R`

```r id="lupqxs"
suppressWarnings(suppressMessages({
  library(dplyr)
}))

# -----------------------------
# A) LME key-term families
# -----------------------------
# Expects columns like:
# ROI_name, model (coupling/moderation), term, p.value
add_fdr_lme_key_terms <- function(lme_key) {
  stopifnot(all(c("ROI_name","model","term","p.value") %in% names(lme_key)))

  lme_key %>%
    mutate(
      fdr_family = case_when(
        model == "coupling" & term == "ROI_cwc" ~ "LME_coupling_within_ROI_cwc",
        model == "coupling" & term == "ROI_pm"  ~ "LME_between_ROI_pm",
        model == "moderation" & grepl("ROI_cwc", term, fixed = TRUE) ~ "LME_moderation_ROI_cwc_x_Group",
        TRUE ~ "LME_other"
      )
    ) %>%
    group_by(fdr_family) %>%
    mutate(q_BH = p.adjust(p.value, method = "BH")) %>%
    ungroup()
}

# -----------------------------
# A2) LME model-test families (LRTs)
# -----------------------------
# Expects columns like:
# ROI_name, p_base_vs_coupling, p_coupling_vs_moderation
add_fdr_lme_model_tests <- function(lme_tests) {
  stopifnot(all(c("ROI_name","p_base_vs_coupling","p_coupling_vs_moderation") %in% names(lme_tests)))

  lme_tests %>%
    mutate(
      q_base_vs_coupling_BH = p.adjust(p_base_vs_coupling, method = "BH"),
      q_coupling_vs_moderation_BH = p.adjust(p_coupling_vs_moderation, method = "BH")
    )
}

# -----------------------------
# B) Estimand-engine families
# -----------------------------
# Expects columns like:
# ROI_name, model, estimand, term, p.value
add_fdr_estimand_grid <- function(est_grid) {
  stopifnot(all(c("ROI_name","model","estimand","term","p.value") %in% names(est_grid)))

  est_grid %>%
    mutate(
      # family = within estimand × model × term (BH across ROIs)
      fdr_family = paste("EST", estimand, model, term, sep = " | ")
    ) %>%
    group_by(fdr_family) %>%
    mutate(q_BH = p.adjust(p.value, method = "BH")) %>%
    ungroup()
}
