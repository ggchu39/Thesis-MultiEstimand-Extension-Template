
### Helper it needs (new): `R/lme_cwc_pm_MultiROI.R`
```r
suppressWarnings(suppressMessages({
  library(dplyr)
  library(lmerTest)
  library(tibble)
}))

fit_cwc_pm_models_multiROI <- function(dat,
                                       outcome = "Y",
                                       id = "ID",
                                       time = "time_point",
                                       age0 = "Age0",
                                       group = "Sex",
                                       roi_value = "ROI_value",
                                       roi_name = "ROI_name") {

  stopifnot(all(c(outcome,id,time,age0,group,roi_value,roi_name) %in% names(dat)))

  rois <- sort(unique(dat[[roi_name]]))

  all_fx <- list()
  all_tests <- list()
  all_key <- list()

  for (r in rois) {

    d0 <- dat %>%
      filter(.data[[roi_name]] == r) %>%
      # complete-case for this ROI analysis
      filter(complete.cases(.data[[outcome]], .data[[roi_value]], .data[[time]], .data[[age0]], .data[[group]], .data[[id]])) %>%
      group_by(.data[[id]]) %>% filter(n() == 2) %>% ungroup()

    # within-between decomposition (2 waves per ID)
    d0 <- d0 %>%
      group_by(.data[[id]]) %>%
      mutate(
        ROI_pm  = mean(.data[[roi_value]], na.rm = FALSE),
        ROI_cwc = .data[[roi_value]] - ROI_pm
      ) %>%
      ungroup()

    n_ID <- n_distinct(d0[[id]])
    n_rows <- nrow(d0)

    # Models
    f_base <- as.formula(paste0(outcome, " ~ ", time, " + ", group, " + ", age0, " + (1|", id, ")"))
    f_cpl  <- as.formula(paste0(outcome, " ~ ", time, " + ", group, " + ", age0, " + ROI_cwc + ROI_pm + (1|", id, ")"))
    f_mod  <- as.formula(paste0(outcome, " ~ ", time, " + ", group, " + ", age0, " + ROI_pm + ROI_cwc*", group, " + (1|", id, ")"))

    m_base <- lmerTest::lmer(f_base, data = d0, REML = FALSE)
    m_cpl  <- lmerTest::lmer(f_cpl,  data = d0, REML = FALSE)
    m_mod  <- lmerTest::lmer(f_mod,  data = d0, REML = FALSE)

    # LRT comparisons (same sample)
    cmp1 <- anova(m_base, m_cpl)
    cmp2 <- anova(m_cpl, m_mod)

    tests <- tibble(
      ROI_name = r,
      n_ID = n_ID,
      n_rows = n_rows,
      AIC_base = AIC(m_base),
      AIC_coupling = AIC(m_cpl),
      AIC_moderation = AIC(m_mod),
      p_base_vs_coupling = cmp1$`Pr(>Chisq)`[2],
      p_coupling_vs_moderation = cmp2$`Pr(>Chisq)`[2]
    )

    # Fixed effects (tidy)
    tidy_fx <- function(m, model_label) {
      sm <- summary(m)
      coefs <- as.data.frame(sm$coefficients)
      coefs$term <- rownames(coefs)
      rownames(coefs) <- NULL

      # lmerTest provides df and p-values (Satterthwaite)
      out <- coefs %>%
        mutate(
          ROI_name = r,
          model = model_label,
          estimate = .data[["Estimate"]],
          std.error = .data[["Std. Error"]],
          df = .data[["df"]],
          statistic = .data[["t value"]],
          p.value = .data[["Pr(>|t|)"]],
          crit = qt(0.975, df),
          conf.low = estimate - crit*std.error,
          conf.high = estimate + crit*std.error,
          n_ID = n_ID,
          n_rows = n_rows
        ) %>%
        select(ROI_name, model, term, estimate, std.error, df, statistic, p.value, conf.low, conf.high, n_ID, n_rows)

      out
    }

    fx <- bind_rows(
      tidy_fx(m_base, "base"),
      tidy_fx(m_cpl,  "coupling"),
      tidy_fx(m_mod,  "moderation")
    )

    # Key terms table (for reporting + later FDR families)
    key <- fx %>%
      filter(
        (model == "coupling" & term %in% c("ROI_cwc","ROI_pm")) |
          (model == "moderation" & grepl("ROI_cwc", term, fixed = TRUE))
      )

    all_fx[[r]] <- fx
    all_tests[[r]] <- tests
    all_key[[r]] <- key
  }

  list(
    fixed_effects = bind_rows(all_fx),
    model_tests   = bind_rows(all_tests),
    key_terms     = bind_rows(all_key)
  )
}
