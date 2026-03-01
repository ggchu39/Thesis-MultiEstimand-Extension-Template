suppressWarnings(suppressMessages({
  library(lmerTest)
}))

fit_lme_single_roi <- function(dat, formula) {
  # Always fit ML (REML=FALSE) so LRT comparisons are valid for fixed-effects changes
  lmerTest::lmer(formula = formula, data = dat, REML = FALSE)
}
