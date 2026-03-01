suppressWarnings(suppressMessages({
  library(dplyr)
  library(tibble)
  library(mediation)
}))

run_mediation_one <- function(dat, outcome, mediator,
                              treat, treat_ref, treat_alt, covar,
                              sims = 2000, seed = 123,
                              method = c("boot","quasi")) {

  method <- match.arg(method)

  d <- dat %>%
    filter(complete.cases(.data[[outcome]], .data[[mediator]], .data[[treat]], .data[[covar]])) %>%
    mutate(
      yvar   = .data[[outcome]],
      medvar = .data[[mediator]],
      treatv = factor(as.character(.data[[treat]]))
    )

  if (!(treat_ref %in% levels(d$treatv) && treat_alt %in% levels(d$treatv))) {
    return(tibble(ok = FALSE, n = nrow(d)))
  }
  if (nrow(d) < 20) {
    return(tibble(ok = FALSE, n = nrow(d)))
  }

  # Mediator and outcome models (matches your extension description)
  m_mod <- lm(medvar ~ treatv + .data[[covar]], data = d)
  y_mod <- lm(yvar   ~ medvar + treatv + .data[[covar]], data = d)

  set.seed(seed)
  med <- mediation::mediate(
    model.m = m_mod,
    model.y = y_mod,
    treat = "treatv",
    mediator = "medvar",
    treat.value = treat_alt,
    control.value = treat_ref,
    sims = sims,
    boot = (method == "boot")
  )

  tibble(
    ok = TRUE,
    n = nrow(d),
    method = method,
    ACME = med$d0,
    ACME_p = med$d0.p,
    ADE  = med$z0,
    ADE_p = med$z0.p,
    total = med$tau.coef,
    total_p = med$tau.p,
    prop_med = med$n0
  )
}

run_mediation_grid <- function(wide_est,
                               roi_name = "ROI_name",
                               outcome,
                               mediator,
                               treat = "Sex",
                               treat_ref = "F",
                               treat_alt = "M",
                               covar = "Age0",
                               sims = 2000,
                               method = c("boot","quasi")) {

  method <- match.arg(method)
  stopifnot(roi_name %in% names(wide_est))

  rois <- sort(unique(wide_est[[roi_name]]))

  bind_rows(lapply(rois, function(r) {
    dat <- wide_est %>% filter(.data[[roi_name]] == r)
    out <- run_mediation_one(dat, outcome, mediator, treat, treat_ref, treat_alt, covar,
                             sims = sims, method = method)
    out %>% mutate(ROI_name = r, outcome = outcome, mediator = mediator)
  }))
}
