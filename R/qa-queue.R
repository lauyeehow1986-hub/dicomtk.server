.extract_surface_coords <- function(mask, spacing_mm) {
  dims <- dim(mask)
  if (length(dims) != 3L) {
    cli::cli_abort("Mask must be a 3D numeric/logical array.")
  }
  bin <- mask > 0
  idx <- which(bin, arr.ind = TRUE)
  if (nrow(idx) == 0L) {
    return(matrix(numeric(0), ncol = 3L))
  }
  nx <- dims[1L]
  ny <- dims[2L]
  nz <- dims[3L]
  is_surf <- vapply(seq_len(nrow(idx)), function(k) {
    i <- idx[k, 1L]
    j <- idx[k, 2L]
    l <- idx[k, 3L]
    if (i == 1L || i == nx || j == 1L || j == ny || l == 1L || l == nz) {
      return(TRUE)
    }
    !(bin[i - 1L, j, l] && bin[i + 1L, j, l] &&
      bin[i, j - 1L, l] && bin[i, j + 1L, l] &&
      bin[i, j, l - 1L] && bin[i, j, l + 1L])
  }, logical(1L))
  pts <- idx[is_surf, , drop = FALSE]
  sweep(pts, 2L, as.numeric(spacing_mm), "*")
}

.min_dists_between <- function(a, b) {
  vapply(seq_len(nrow(a)), function(i) {
    d2 <- (b[, 1L] - a[i, 1L])^2 + (b[, 2L] - a[i, 2L])^2 + (b[, 3L] - a[i, 3L])^2
    sqrt(min(d2))
  }, numeric(1L))
}

#' Compute 3D Segmentation QA Metrics (Dice, HD95, Surface Dice)
#'
#' @param pred_mask 3D binary/logical predicted mask array.
#' @param ref_mask 3D binary/logical reference mask array of identical dims.
#' @param spacing_mm Numeric vector of length 3 giving voxel spacing in mm.
#' @param tolerance_mm Surface Dice tolerance in mm (default `1.0`).
#'
#' @return A list with `dice`, `hd95_mm`, and `surface_dice`.
#' @examples
#' m <- array(0L, dim = c(6L, 6L, 6L))
#' m[2:4, 2:4, 2:4] <- 1L
#' compute_seg_qa(m, m)
#' @export
compute_seg_qa <- function(pred_mask,
                           ref_mask,
                           spacing_mm = c(1, 1, 1),
                           tolerance_mm = 1.0) {
  if (!identical(dim(pred_mask), dim(ref_mask))) {
    cli::cli_abort("{.arg pred_mask} and {.arg ref_mask} must have identical dimensions.")
  }
  p_bin <- pred_mask > 0
  r_bin <- ref_mask > 0
  p_sum <- sum(p_bin)
  r_sum <- sum(r_bin)

  if (p_sum == 0L && r_sum == 0L) {
    return(list(dice = 1.0, hd95_mm = 0.0, surface_dice = 1.0))
  }
  if (p_sum == 0L || r_sum == 0L) {
    return(list(dice = 0.0, hd95_mm = Inf, surface_dice = 0.0))
  }

  tp <- sum(p_bin & r_bin)
  dice <- (2.0 * tp) / (p_sum + r_sum)

  s_p <- .extract_surface_coords(p_bin, spacing_mm)
  s_r <- .extract_surface_coords(r_bin, spacing_mm)
  d_pr <- .min_dists_between(s_p, s_r)
  d_rp <- .min_dists_between(s_r, s_p)

  all_d <- c(d_pr, d_rp)
  hd95 <- as.numeric(stats::quantile(all_d, probs = 0.95, names = FALSE))
  surface_dice <- (sum(d_pr <= tolerance_mm) + sum(d_rp <= tolerance_mm)) / (length(d_pr) + length(d_rp))

  list(
    dice = as.numeric(dice),
    hd95_mm = hd95,
    surface_dice = as.numeric(surface_dice)
  )
}

#' Initialize a QA Review Queue
#'
#' @param logger Optional `"dicom_audit_logger"` for QA review actions.
#' @return An S3 `"dicom_qa_queue"` object.
#' @export
qa_queue_init <- function(logger = NULL) {
  structure(
    list(
      logger = logger,
      items = new.env(parent = emptyenv())
    ),
    class = "dicom_qa_queue"
  )
}

#' Enqueue a Study or Segmentation into the QA Review Queue
#'
#' @param qa_queue A `"dicom_qa_queue"` object from [qa_queue_init()].
#' @param project_id Project identifier.
#' @param study_uid StudyInstanceUID string.
#' @param pred_mask Optional 3D predicted mask array.
#' @param ref_mask Optional 3D reference mask array.
#' @param spacing_mm Voxel spacing in mm (default `c(1, 1, 1)`).
#' @param tolerance_mm Surface Dice tolerance in mm (default `1.0`).
#' @param metrics Optional pre-computed list of QA metrics.
#' @param priority Priority label (`"normal"`, `"high"`, `"urgent"`).
#'
#' @return Enqueued QA item list.
#' @export
qa_enqueue <- function(qa_queue,
                       project_id,
                       study_uid,
                       pred_mask = NULL,
                       ref_mask = NULL,
                       spacing_mm = c(1, 1, 1),
                       tolerance_mm = 1.0,
                       metrics = NULL,
                       priority = "normal") {
  if (!inherits(qa_queue, "dicom_qa_queue")) {
    cli::cli_abort("{.arg qa_queue} must be a {.cls dicom_qa_queue} object.")
  }
  if (is.null(metrics) && !is.null(pred_mask) && !is.null(ref_mask)) {
    metrics <- compute_seg_qa(pred_mask, ref_mask, spacing_mm = spacing_mm, tolerance_mm = tolerance_mm)
  }
  item_id <- paste0("qa_", substr(srv_hash_hex(paste0(project_id, study_uid, Sys.time(), stats::runif(1L))), 1L, 12L))
  item <- list(
    item_id = item_id,
    project_id = project_id,
    study_uid = study_uid,
    priority = priority,
    status = "pending",
    dice = if (!is.null(metrics)) metrics$dice else NA_real_,
    hd95_mm = if (!is.null(metrics)) metrics$hd95_mm else NA_real_,
    surface_dice = if (!is.null(metrics)) metrics$surface_dice else NA_real_,
    reviewed_by = NA_character_,
    notes = NA_character_,
    created_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  )
  assign(item_id, item, envir = qa_queue$items)
  item
}

#' Submit a QA Review Decision
#'
#' Requires `"qa_review"` capability (`pi`, `annotator`, or `admin`).
#'
#' @param qa_queue A `"dicom_qa_queue"` object.
#' @param principal Authenticated `"dicom_server_principal"`.
#' @param item_id QA item identifier returned by [qa_enqueue()].
#' @param decision Review decision: `"approve"`, `"reject"`, or `"revise"`.
#' @param notes Optional reviewer notes.
#'
#' @return Updated QA item list.
#' @export
qa_submit_review <- function(qa_queue,
                             principal,
                             item_id,
                             decision = c("approve", "reject", "revise"),
                             notes = NULL) {
  decision <- match.arg(decision)
  srv_check_scalar_chr(item_id, "item_id")
  if (!exists(item_id, envir = qa_queue$items, inherits = FALSE)) {
    cli::cli_abort("QA item {.val {item_id}} not found.")
  }
  item <- get(item_id, envir = qa_queue$items, inherits = FALSE)
  check_permission(principal, "qa_review", project_id = item$project_id, throw = TRUE)

  status_map <- c(approve = "approved", reject = "rejected", revise = "needs_revision")
  item$status <- unname(status_map[[decision]])
  item$reviewed_by <- principal$user_id
  item$notes <- notes %||% NA_character_
  assign(item_id, item, envir = qa_queue$items)

  if (!is.null(qa_queue$logger)) {
    audit_append(
      qa_queue$logger,
      actor = principal$user_id,
      action = "qa_review",
      project_id = item$project_id,
      details = list(item_id = item_id, decision = decision, status = item$status)
    )
  }
  item
}

#' List QA Queue Items
#'
#' @param qa_queue A `"dicom_qa_queue"` object.
#' @param project_id Optional project filter.
#' @param status Optional status filter (`"pending"`, `"approved"`, etc.).
#' @return A `tibble::tibble` of QA items.
#' @export
qa_list <- function(qa_queue, project_id = NULL, status = NULL) {
  ids <- ls(envir = qa_queue$items, all.names = FALSE)
  if (length(ids) == 0L) {
    return(tibble::tibble(
      item_id = character(0), project_id = character(0), study_uid = character(0),
      priority = character(0), status = character(0), dice = numeric(0),
      hd95_mm = numeric(0), surface_dice = numeric(0), reviewed_by = character(0)
    ))
  }
  rows <- lapply(ids, function(id) {
    it <- get(id, envir = qa_queue$items, inherits = FALSE)
    tibble::tibble(
      item_id = it$item_id,
      project_id = it$project_id,
      study_uid = it$study_uid,
      priority = it$priority,
      status = it$status,
      dice = it$dice,
      hd95_mm = it$hd95_mm,
      surface_dice = it$surface_dice,
      reviewed_by = it$reviewed_by
    )
  })
  tbl <- do.call(rbind, rows)
  if (!is.null(project_id)) tbl <- tbl[tbl$project_id == project_id, , drop = FALSE]
  if (!is.null(status)) tbl <- tbl[tbl$status == status, , drop = FALSE]
  tibble::as_tibble(tbl)
}
