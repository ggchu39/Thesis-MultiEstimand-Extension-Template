# QC + construction helpers for two-wave long data
# Builds two streams:
# - dat_roi_only: needs ROI + time/age/sex (trajectory analyses)
# - dat_roi_y   : needs ROI + Y + time/age/sex (coupling/change-score analyses)

suppressWarnings(suppressMessages({
  library(dplyr)
  library(tidyr)
  library(tibble)
}))

build_qc_two_wave_streams <- function(df_long,
                                      id_col,
                                      wave_col,
                                      wave_map = c("T1" = 0L, "T2" = 1L),
                                      baseline_age_col,
                                      sex_col,
                                      outcome_col,
                                      roi_left_col,
                                      roi_right_col,
                                      followup_years = 4,
                                      collapse_duplicates = TRUE) {
  stopifnot(is.data.frame(df_long))
  stopifnot(all(c(id_col, wave_col, baseline_age_col, sex_col, outcome_col, roi_left_col, roi_right_col) %in% names(df_long)))
  stopifnot(all(names(wave_map) %in% unique(df_long[[wave_col]])))
  stopifnot(followup_years > 0)

  df0 <- df_long %>%
    transmute(
      ID   = as.character(.data[[id_col]]),
      wave = as.character(.data[[wave_col]]),
      Sex  = factor(as.character(.data[[sex_col]])),
      Age0 = as.numeric(.data[[baseline_age_col]]),
      Y    = as.numeric(.data[[outcome_col]]),
      ROI_L = as.numeric(.data[[roi_left_col]]),
      ROI_R = as.numeric(.data[[roi_right_col]])
    ) %>%
    mutate(
      time_point = unname(wave_map[wave]),
      Time_years = followup_years * time_point,
      Age_at_assessment = Age0 + Time_years,
      ROI_mean = rowMeans(cbind(ROI_L, ROI_R), na.rm = FALSE)
    )

  # Stream A: ROI-only (trajectory)
  need_roi_only <- c("ID","wave","Sex","Age0","time_point","Time_years","Age_at_assessment","ROI_mean")
  df_roi_only0 <- df0 %>% select(all_of(need_roi_only))

  df_roi_only1 <- df_roi_only0 %>% filter(complete.cases(.))
  dropped_rows_roi_only <- df_roi_only0 %>% filter(!complete.cases(.))

  # Stream B: ROI + Y (coupling/change-score)
  need_roi_y <- c(need_roi_only, "Y")
  df_roi_y0 <- df0 %>% select(all_of(need_roi_y))

  df_roi_y1 <- df_roi_y0 %>% filter(complete.cases(.))
  dropped_rows_roi_y <- df_roi_y0 %>% filter(!complete.cases(.))

  # Duplicate consistency check (both streams share ID×time_point)
  dup_check <- function(d) {
    d %>%
      group_by(ID, time_point) %>%
      summarise(
        n_rows = n(),
        nSex   = n_distinct(Sex),
        nAge0  = n_distinct(Age0),
        .groups = "drop"
      ) %>%
      filter(n_rows > 1 & (nSex > 1 | nAge0 > 1))
  }
  dup_inconsistency <- bind_rows(
    dup_check(df_roi_only1) %>% mutate(stream = "roi_only"),
    dup_check(df_roi_y1)    %>% mutate(stream = "roi_y")
  )

  # Collapse duplicates within ID×time_point (mean numeric, keep first for invariant fields)
  collapse_id_wave <- function(d, keep_y = FALSE) {
    if (!collapse_duplicates) return(d)

    if (keep_y) {
      d %>%
        group_by(ID, time_point) %>%
        summarise(
          wave = first(wave),
          Sex  = first(Sex),
          Age0 = first(Age0),
          Time_years = first(Time_years),
          Age_at_assessment = first(Age_at_assessment),
          ROI_mean = mean(ROI_mean),
          Y = mean(Y),
          .groups = "drop"
        )
    } else {
      d %>%
        group_by(ID, time_point) %>%
        summarise(
          wave = first(wave),
          Sex  = first(Sex),
          Age0 = first(Age0),
          Time_years = first(Time_years),
          Age_at_assessment = first(Age_at_assessment),
          ROI_mean = mean(ROI_mean),
          .groups = "drop"
        )
    }
  }

  df_roi_only2 <- collapse_id_wave(df_roi_only1, keep_y = FALSE)
  df_roi_y2    <- collapse_id_wave(df_roi_y1, keep_y = TRUE)

  # Enforce exactly 2 waves per ID (T1 + T2)
  enforce_two_waves <- function(d) {
    d %>%
      group_by(ID) %>%
      filter(n_distinct(time_point) == 2, n() == 2) %>%
      ungroup()
  }

  dat_roi_only <- enforce_two_waves(df_roi_only2)
  dat_roi_y    <- enforce_two_waves(df_roi_y2)

  # Center baseline age within each final analysis sample
  dat_roi_only <- dat_roi_only %>% mutate(Age0_c = Age0 - mean(Age0, na.rm = TRUE))
  dat_roi_y    <- dat_roi_y    %>% mutate(Age0_c = Age0 - mean(Age0, na.rm = TRUE))

  qc_summary <- tibble(
    stream = c("roi_only","roi_y"),
    n_rows = c(nrow(dat_roi_only), nrow(dat_roi_y)),
    n_ID   = c(n_distinct(dat_roi_only$ID), n_distinct(dat_roi_y$ID)),
    age0_min = c(min(dat_roi_only$Age0), min(dat_roi_y$Age0)),
    age0_max = c(max(dat_roi_only$Age0), max(dat_roi_y$Age0))
  )

  list(
    dat_roi_only = dat_roi_only,
    dat_roi_y = dat_roi_y,
    qc_summary = qc_summary,
    dropped_rows_roi_only = dropped_rows_roi_only,
    dropped_rows_roi_y = dropped_rows_roi_y,
    dup_inconsistency = dup_inconsistency
  )
}
