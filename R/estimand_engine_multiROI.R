
---

### 2) Add helper `R/estimand_engine_multiROI.R`

```r
suppressWarnings(suppressMessages({
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(broom)
}))

# Safe % change and log ratio helpers
pct_change <- function(w2, w1) {
  ifelse(is.na(w1) | is.na(w2) | w1 == 0, NA_real_, (w2 - w1) / w1 * 100)
}
log_ratio <- function(w2, w1) {
  ifelse(is.na(w1) | is.na(w2) | w1 <= 0 | w2 <= 0, NA_real_, log(w2 / w1))
}

# Build a wide paired table per ROI_name:
# one row per (ID, ROI_name) with Y_t0/Y_t1 and ROI_t0/ROI_t1 plus covariates
make_wide_change_table_multiROI <- function(dat_roi_long,
                                           id = "ID",
                                           roi_name = "ROI_name",
                                           time = "time_point",
                                           roi_value = "ROI_value",
                                           outcome_long,
                                           outcome = "Y",
                                           group = "Sex",
                                           age0 = "Age0") {

  stopifnot(all(c(id, roi_name, time, roi_value) %in% names(dat_roi_long)))
  stopifnot(all(c(id, time, outcome, group, age0) %in% names(outcome_long)))

  # Extract ROI values
  roi_wide <- dat_roi_long %>%
    select(all_of(c(id, roi_name, time, roi_value))) %>%
    pivot_wider(
      names_from = all_of(time),
      values_from = all_of(roi_value),
      names_prefix = "ROI_t"
    )

  # Extract outcome/covariates (one row per ID per time)
  y_wide <- outcome_long %>%
    select(all_of(c(id, time, outcome, group, age0))) %>%
    pivot_wider(
      names_from = all_of(time),
      values_from = all_of(outcome),
      names_prefix = "Y_t"
    ) %>%
    # keep ID-level covariates from baseline (time 0) conceptually:
    # here we just take the first non-missing by ID
    group_by(.data[[id]]) %>%
    summarise(
      across(starts_with("Y_t"), ~first(.x)),
      !!group := first(.data[[group]]),
      !!age0  := first(.data[[age0]]),
      .groups = "drop"
    )

  # Join by ID; ROI_name remains per row
  wide <- roi_wide %>%
    left_join(y_wide, by = setNames(id, id))

  # Require complete paired ROI and paired outcome for estimands
  wide <- wide %>%
    filter(
      complete.cases(.data[["ROI_t0"]], .data[["ROI_t1"]],
                     .data[["Y_t0"]],   .data[["Y_t1"]],
                     .data[[group]], .data[[age0]])
    )

  wide
}

# Add estimands for Y and ROI
add_estimands_multiROI <- function(wide_roi, y_prefix = "Y", x_prefix = "ROI") {

  w <- wide_roi

  # Outcome estimands
  y0 <- w[[paste0(y_prefix, "_t0")]]
  y1 <- w[[paste0(y_prefix, "_t1")]]
  w$dY_raw <- y1 - y0
  w$dY_pct <- pct_change(y1, y0)
  w$dY_log <- log_ratio(y1, y0)
  w$dY_abs <- abs(y1 - y0)

  # ROI estimands
  x0 <- w[[paste0(x_prefix, "_t0")]]
  x1 <- w[[paste0(x_prefix, "_t1")]]
  w$dROI_raw <- x1 - x0
  w$dROI_pct <- pct_change(x1, x0)
  w$dROI_log <- log_ratio(x1, x0)
  w$dROI_abs <- abs(x1 - x0)

  w
}

# Run models across a grid of estimands (v3x style)
run_estimand_grid_models <- function(wide_est, group = "Sex", age0 = "Age0") {

  stopifnot(all(c("ROI_name", group, age0,
                  "dY_raw","dY_pct","dY_log","dY_abs",
                  "dROI_raw","dROI_pct","dROI_log","dROI_abs") %in% names(wide_est)))

  pairs <- tibble::tribble(
    ~estimand, ~y,      ~x,
    "raw",     "dY_raw","dROI_raw",
    "pct",     "dY_pct","dROI_pct",
    "log",     "dY_log","dROI_log",
    "abs",     "dY_abs","dROI_abs"
  )

  run_one <- function(d, y, x, estimand_label) {
    # coupling
    f1 <- as.formula(paste0(y, " ~ ", x, " + ", age0, " + ", group))
    # moderation
    f2 <- as.formula(paste0(y, " ~ ", x, " * ", group, " + ", age0))

    m1 <- lm(f1, data = d)
    m2 <- lm(f2, data = d)

    bind_rows(
      broom::tidy(m1) %>% mutate(model = "coupling", estimand = estimand_label),
      broom::tidy(m2) %>% mutate(model = "moderation", estimand = estimand_label)
    )
  }

  res <- wide_est %>%
    group_by(ROI_name) %>%
    group_modify(~{
      d <- .x
      bind_rows(lapply(seq_len(nrow(pairs)), function(i) {
        run_one(d, pairs$y[i], pairs$x[i], pairs$estimand[i])
      }))
    }) %>%
    ungroup()

  # Attach sample size per ROI_name
  n_tbl <- wide_est %>%
    group_by(ROI_name) %>%
    summarise(n = n(), .groups = "drop")

  res <- res %>% left_join(n_tbl, by = "ROI_name")

  res
}
