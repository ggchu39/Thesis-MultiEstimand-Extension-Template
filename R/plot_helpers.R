suppressWarnings(suppressMessages({
  library(ggplot2)
  library(tibble)
}))

plot_spaghetti_with_gam <- function(dat, x, y, id, gam_model, title, xlab, ylab) {
  # Create grid predictions (no explicit colors specified)
  grid <- tibble(
    xval = seq(min(dat[[x]], na.rm = TRUE), max(dat[[x]], na.rm = TRUE), length.out = 200)
  )
  names(grid) <- x
  pred <- predict(gam_model, newdata = grid, se.fit = TRUE, type = "response")
  grid$fit <- as.numeric(pred$fit)
  grid$se  <- as.numeric(pred$se.fit)
  grid$lo  <- grid$fit - 1.96 * grid$se
  grid$hi  <- grid$fit + 1.96 * grid$se

  ggplot(dat, aes(x = .data[[x]], y = .data[[y]], group = .data[[id]])) +
    geom_line(alpha = 0.25, linewidth = 0.4) +
    geom_point(alpha = 0.25, size = 1.0) +
    geom_ribbon(data = grid, aes(ymin = lo, ymax = hi), inherit.aes = FALSE, alpha = 0.18) +
    geom_line(data = grid, aes(y = fit), inherit.aes = FALSE, linewidth = 1.1) +
    labs(title = title, x = xlab, y = ylab) +
    theme_classic(base_size = 14)
}

plot_spaghetti_with_gam_by_group <- function(dat, x, y, id, group, gam_model, title, xlab, ylab) {
  grid <- expand.grid(
    xval = seq(min(dat[[x]], na.rm = TRUE), max(dat[[x]], na.rm = TRUE), length.out = 200),
    gval = levels(dat[[group]])
  )
  grid <- as_tibble(grid)
  names(grid) <- c(x, group)

  pred <- predict(gam_model, newdata = grid, se.fit = TRUE, type = "response")
  grid$fit <- as.numeric(pred$fit)
  grid$se  <- as.numeric(pred$se.fit)
  grid$lo  <- grid$fit - 1.96 * grid$se
  grid$hi  <- grid$fit + 1.96 * grid$se

  ggplot(dat, aes(x = .data[[x]], y = .data[[y]], group = .data[[id]])) +
    geom_line(alpha = 0.20, linewidth = 0.35) +
    geom_point(alpha = 0.20, size = 0.9) +
    geom_ribbon(data = grid, aes(ymin = lo, ymax = hi, fill = .data[[group]]),
                inherit.aes = FALSE, alpha = 0.16, colour = NA) +
    geom_line(data = grid, aes(y = fit, colour = .data[[group]]),
              inherit.aes = FALSE, linewidth = 1.1) +
    labs(title = title, x = xlab, y = ylab) +
    theme_classic(base_size = 14)
}
