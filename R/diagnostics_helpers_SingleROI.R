# Simple diagnostic plot saver for LME models (public-safe)
save_lme_diagnostics <- function(mod, file, width = 1400, height = 1100, res = 160) {
  png(file, width = width, height = height, res = res)
  op <- par(mfrow = c(2, 2))
  on.exit({par(op); dev.off()}, add = TRUE)

  r <- resid(mod)
  f <- fitted(mod)

  plot(f, r, xlab = "Fitted", ylab = "Residuals", main = "Residuals vs fitted")
  abline(h = 0, lty = 2)

  qqnorm(r, main = "Normal Q-Q")
  qqline(r)

  hist(r, breaks = 30, main = "Residual histogram", xlab = "Residuals")

  plot(seq_along(r), r, xlab = "Index", ylab = "Residuals", main = "Residuals vs index")
  abline(h = 0, lty = 2)
}
