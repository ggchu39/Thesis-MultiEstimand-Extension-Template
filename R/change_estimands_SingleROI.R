suppressWarnings(suppressMessages({
  library(dplyr)
}))

# Adds change estimands for each variable in `vars`.
# Expects wide columns like: VAR_t0 and VAR_t1 (suffixes configurable).
add_change_estimands <- function(wide, vars, t1_suffix = "t0", t2_suffix = "t1") {
  out <- wide

  for (v in vars) {
    x1 <- out[[paste0(v, "_", t1_suffix)]]
    x2 <- out[[paste0(v, "_", t2_suffix)]]

    out[[paste0("d", v, "_raw")]] <- x2 - x1
    out[[paste0("d", v, "_pct")]] <- 100 * (x2 - x1) / x1
    out[[paste0("d", v, "_log")]] <- log(x2 / x1)
    out[[paste0("d", v, "_abs")]] <- abs(x2 - x1)
  }

  out
}

# Fit ΔOutcome ~ ΔPredictor + covars across all estimands.
# outcome_prefix e.g., "dY"
# predictor_prefix e.g., "dROI_mean"
run_change_link_models <- function(wide_chg, outcome_prefix, predictor_prefix, covars = c("Age0","Sex")) {
  estimands <- c("raw","pct","log","abs")

  res <- lapply(estimands, function(est) {
    y_col <- paste0(outcome_prefix, "_", est)
    x_col <- paste0(predictor_prefix, "_", est)

    fml <- as.formula(paste(y_col, "~", x_col, "+", paste(covars, collapse = " + ")))
    fit <- lm(fml, data = wide_chg)

    s <- summary(fit)
    b <- coef(s)[x_col, "Estimate"]
    se <- coef(s)[x_col, "Std. Error"]
    p  <- coef(s)[x_col, "Pr(>|t|)"]
    r2 <- s$r.squared

    data.frame(
      estimand = est,
      outcome = y_col,
      predictor = x_col,
      beta = b,
      se = se,
      p = p,
      r2 = r2,
      stringsAsFactors = FALSE
    )
  })

  do.call(rbind, res)
}
