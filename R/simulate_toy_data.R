# Simulate toy two-wave longitudinal data 
# Output columns: ID, wave (T1/T2), Age0, Sex, Y, ROI_L, ROI_R
# Notes:
# - Age0 is baseline age repeated at both waves (common in 2-wave datasets)
# - Age_at_assessment is derived later as Age0 + followup_years*time_point
# - ROI and Y include subject random effects + change + noise

simulate_toy_two_wave_long <- function(n_id = 120, followup_years = 4, seed = 1) {
  stopifnot(n_id >= 10, followup_years > 0)
  set.seed(seed)

  ID <- sprintf("ID%04d", seq_len(n_id))
  Sex <- sample(c("F", "M"), size = n_id, replace = TRUE)
  Age0 <- round(runif(n_id, min = 20, max = 80), 0)

  # Participant random intercepts (toy)
  u_roi <- rnorm(n_id, 0, 0.25)
  u_y   <- rnorm(n_id, 0, 0.40)

  # Create 2 rows per ID: T1 and T2
  df <- expand.grid(ID = ID, wave = c("T1", "T2"), KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)

  df <- df |>
    transform(
      Sex = Sex[match(ID, ID)],
      Age0 = Age0[match(ID, ID)],
      time_point = ifelse(wave == "T1", 0L, 1L),
      Time_years = followup_years * time_point
    )

  # Toy ROI mean trajectory: baseline age + time + age*time + individual intercept + noise
  Age0_c <- df$Age0 - mean(df$Age0)

  roi_mean <- 1.5 +
    (-0.003 * Age0_c) +
    (-0.02 * df$time_point) +
    (-0.0005 * Age0_c * df$Time_years) +
    u_roi[match(df$ID, ID)] +
    rnorm(nrow(df), 0, 0.10)

  # Split ROI into left/right with tiny lateral noise
  df$ROI_L <- roi_mean + rnorm(nrow(df), 0, 0.03)
  df$ROI_R <- roi_mean + rnorm(nrow(df), 0, 0.03)

  # Toy outcome Y: baseline age + time + coupling to ROI mean + individual intercept + noise
  # (Purely for demonstration; no scientific meaning)
  df$Y <- 50 +
    (-0.06 * Age0_c) +
    (-0.8 * df$time_point) +
    (2.0 * roi_mean) +
    u_y[match(df$ID, ID)] +
    rnorm(nrow(df), 0, 2.0)

  # Keep only public-safe columns (time variables derived later in QC helper)
  df <- df[, c("ID", "wave", "Age0", "Sex", "Y", "ROI_L", "ROI_R")]

  df
}





