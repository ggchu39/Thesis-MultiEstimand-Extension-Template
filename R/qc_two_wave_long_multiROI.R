suppressWarnings(suppressMessages({
  library(dplyr)
  library(tibble)
}))

build_qc_two_wave_multiROI <- function(df_long,
                                       id_col, wave_col, wave_map = c("T1"=0L,"T2"=1L),
                                       baseline_age_col, sex_col, outcome_col,
                                       followup_years = 4,
                                       collapse_duplicates = TRUE) {
  stopifnot(all(c(id_col, wave_col, baseline_age_col, sex_col, outcome_col) %in% names(df_long)))

  # Keep everything (including ROI columns) but standardize key fields
  df0 <- df_long %>%
    mutate(
      ID   = as.character(.data[[id_col]]),
      wave = as.character(.data[[wave_col]]),
      Sex  = factor(as.character(.data[[sex_col]])),
      Age0 = as.numeric(.data[[baseline_age_col]]),
      Y    = as.numeric(.data[[outcome_col]]),
      time_point = unname(wave_map[wave])
    ) %>%
    filter(!is.na(time_point))

  # Add age timeline variables (design-based)
  df0 <- df0 %>%
    mutate(
      Time_years = followup_years * time_point,
      Age_TP = Age0 + Time_years,
      Age_mid = Age0 + followup_years/2,
      Age_at_assessment = Age_TP
    )

  # Drop missingness only for core fields here (ROI missingness handled later when reshaping)
  core_needed <- c("ID","wave","Sex","Age0","Y","time_point","Time_years","Age_TP","Age_mid","Age_at_assessment")
  df1 <- df0 %>% filter(complete.cases(df0[, core_needed]))
  dropped_rows <- df0 %>% filter(!complete.cases(df0[, core_needed]))

  # Duplicate consistency check within ID×time_point for Sex/Age0
  dup_inconsistency <- df1 %>%
    group_by(ID, time_point) %>%
    summarise(
      n_rows = n(),
      nSex   = n_distinct(Sex),
      nAge0  = n_distinct(Age0),
      .groups = "drop"
    ) %>%
    filter(n_rows > 1 & (nSex > 1 | nAge0 > 1))

  # Collapse duplicates within ID×time_point if requested
  df2 <- df1
  if (collapse_duplicates) {
    # For numeric columns we take the mean; for non-numeric we take first.
    # This is safe for toy data and prevents many-to-many amplification.
    df2 <- df1 %>%
      group_by(ID, time_point) %>%
      summarise(
        across(where(is.numeric), ~mean(.x)),
        across(where(~!is.numeric(.x)), ~first(.x)),
        .groups = "drop"
      )
  }

  # Enforce exactly 2 waves per ID
  dat_long_core <- df2 %>%
    group_by(ID) %>%
    filter(n_distinct(time_point) == 2, n() == 2) %>%
    ungroup() %>%
    mutate(Age0_c = Age0 - mean(Age0, na.rm = TRUE))

  qc_summary <- tibble(
    n_rows = nrow(dat_long_core),
    n_ID   = n_distinct(dat_long_core$ID),
    age0_min = min(dat_long_core$Age0),
    age0_max = max(dat_long_core$Age0),
    followup_years = followup_years
  )

  list(
    dat_long_core = dat_long_core,
    qc_summary = qc_summary,
    dropped_rows = dropped_rows,
    dup_inconsistency = dup_inconsistency
  )
}
