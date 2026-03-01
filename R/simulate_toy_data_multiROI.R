
---

## 2) New helper files needed for Step 01

### `R/simulate_toy_data_multiROI.R`

```r
simulate_toy_two_wave_long_multiROI <- function(n_id = 120, followup_years = 4, seed = 2) {
  stopifnot(n_id >= 10, followup_years > 0)
  set.seed(seed)

  ID  <- sprintf("ID%04d", seq_len(n_id))
  Sex <- sample(c("F","M"), size = n_id, replace = TRUE)
  Age0 <- round(runif(n_id, 20, 80), 0)

  df <- expand.grid(ID = ID, wave = c("T1","T2"), KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  df$Sex <- Sex[match(df$ID, ID)]
  df$Age0 <- Age0[match(df$ID, ID)]
  df$time_point <- ifelse(df$wave == "T1", 0L, 1L)
  df$Time_years <- followup_years * df$time_point

  Age0_c <- df$Age0 - mean(df$Age0)

  # participant-level random intercepts per ROI and Y
  uA <- rnorm(n_id, 0, 0.20)
  uB <- rnorm(n_id, 0, 0.20)
  uC <- rnorm(n_id, 0, 0.20)
  uY <- rnorm(n_id, 0, 0.50)

  # ROI latent means (toy)
  ROI_A <- 1.6 + (-0.003*Age0_c) + (-0.02*df$time_point) + uA[match(df$ID, ID)] + rnorm(nrow(df),0,0.10)
  ROI_B <- 1.3 + (-0.002*Age0_c) + (-0.03*df$time_point) + uB[match(df$ID, ID)] + rnorm(nrow(df),0,0.10)
  ROI_C <- 1.1 + (-0.001*Age0_c) + (-0.01*df$time_point) + uC[match(df$ID, ID)] + rnorm(nrow(df),0,0.10)

  # split to L/R
  df$ROI_A_L <- ROI_A + rnorm(nrow(df),0,0.03)
  df$ROI_A_R <- ROI_A + rnorm(nrow(df),0,0.03)
  df$ROI_B_L <- ROI_B + rnorm(nrow(df),0,0.03)
  df$ROI_B_R <- ROI_B + rnorm(nrow(df),0,0.03)
  df$ROI_C_L <- ROI_C + rnorm(nrow(df),0,0.03)
  df$ROI_C_R <- ROI_C + rnorm(nrow(df),0,0.03)

  # toy outcome depends on ROI_A most strongly (purely illustrative)
  df$Y <- 50 + (-0.06*Age0_c) + (-0.8*df$time_point) +
    2.0*ROI_A + 0.5*ROI_B + 0.2*ROI_C +
    uY[match(df$ID, ID)] + rnorm(nrow(df), 0, 2.0)

  df <- df[, c("ID","wave","Age0","Sex","Y",
               "ROI_A_L","ROI_A_R","ROI_B_L","ROI_B_R","ROI_C_L","ROI_C_R")]
  df
}
