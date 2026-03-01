suppressWarnings(suppressMessages({
  library(dplyr)
  library(tidyr)
}))

reshape_rois_to_long <- function(dat_long, roi_pairs, require_both_sides = TRUE) {
  # roi_pairs: named list like list(ROI_A=c("ROI_A_L","ROI_A_R"), ...)
  stopifnot(is.list(roi_pairs), length(roi_pairs) >= 1)

  out <- lapply(names(roi_pairs), function(nm) {
    cols <- roi_pairs[[nm]]
    stopifnot(length(cols) == 2, all(cols %in% names(dat_long)))

    tmp <- dat_long %>%
      mutate(
        ROI_name = nm,
        ROI_L = .data[[cols[1]]],
        ROI_R = .data[[cols[2]]],
        ROI_value = rowMeans(cbind(ROI_L, ROI_R), na.rm = FALSE)
      )

    if (require_both_sides) {
      tmp <- tmp %>% filter(!is.na(ROI_L) & !is.na(ROI_R))
    }

    tmp %>%
      select(-ROI_L, -ROI_R)
  })

  bind_rows(out)
}
