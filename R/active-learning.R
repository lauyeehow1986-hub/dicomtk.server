#' Initialize a MONAI Label / Active Learning Candidate Pool
#'
#' @param strategy Selection strategy: `"uncertainty"`, `"fifo"`, or `"random"`.
#' @param logger Optional `"dicom_audit_logger"` for label submission auditing.
#' @return An S3 `"dicom_active_learning_pool"` object.
#' @examples
#' pool <- active_learning_pool_init(strategy = "uncertainty")
#' pool$strategy
#' @export
active_learning_pool_init <- function(strategy = c("uncertainty", "fifo", "random"),
                                      logger = NULL) {
  strategy <- match.arg(strategy)
  structure(
    list(
      strategy = strategy,
      logger = logger,
      candidates = new.env(parent = emptyenv())
    ),
    class = "dicom_active_learning_pool"
  )
}

#' Add an Unlabeled Study Candidate to the Active Learning Pool
#'
#' @param pool A `"dicom_active_learning_pool"` object.
#' @param project_id Project identifier.
#' @param study_uid StudyInstanceUID string.
#' @param uncertainty_score Model uncertainty score in `[0, 1]`.
#' @param metadata Optional named list of study metadata.
#'
#' @return Candidate record list.
#' @export
active_learning_add_candidate <- function(pool,
                                          project_id,
                                          study_uid,
                                          uncertainty_score = 0.5,
                                          metadata = list()) {
  if (!inherits(pool, "dicom_active_learning_pool")) {
    cli::cli_abort("{.arg pool} must be a {.cls dicom_active_learning_pool} object.")
  }
  cid <- paste0("al_", substr(srv_hash_hex(paste0(project_id, study_uid, Sys.time(), stats::runif(1L))), 1L, 12L))
  rec <- list(
    candidate_id = cid,
    project_id = project_id,
    study_uid = study_uid,
    uncertainty_score = as.numeric(uncertainty_score),
    status = "unlabeled",
    label_path = NA_character_,
    quality_score = NA_real_,
    labeled_by = NA_character_,
    added_at = Sys.time(),
    metadata = metadata
  )
  assign(cid, rec, envir = pool$candidates)
  rec
}

#' Select Next Candidate(s) for Annotation
#'
#' @param pool A `"dicom_active_learning_pool"` object.
#' @param project_id Optional project filter.
#' @param n Maximum number of candidates to return (default `1L`).
#'
#' @return A `tibble::tibble` of prioritized unlabeled candidates.
#' @export
active_learning_next <- function(pool, project_id = NULL, n = 1L) {
  ids <- ls(envir = pool$candidates, all.names = FALSE)
  if (length(ids) == 0L) {
    return(tibble::tibble(
      candidate_id = character(0), project_id = character(0),
      study_uid = character(0), uncertainty_score = numeric(0), status = character(0)
    ))
  }
  recs <- lapply(ids, function(id) get(id, envir = pool$candidates, inherits = FALSE))
  recs <- Filter(function(r) {
    identical(r$status, "unlabeled") && (is.null(project_id) || identical(r$project_id, project_id))
  }, recs)

  if (length(recs) == 0L) {
    return(tibble::tibble(
      candidate_id = character(0), project_id = character(0),
      study_uid = character(0), uncertainty_score = numeric(0), status = character(0)
    ))
  }

  tbl <- tibble::tibble(
    candidate_id = vapply(recs, `[[`, character(1L), "candidate_id"),
    project_id = vapply(recs, `[[`, character(1L), "project_id"),
    study_uid = vapply(recs, `[[`, character(1L), "study_uid"),
    uncertainty_score = vapply(recs, `[[`, numeric(1L), "uncertainty_score"),
    status = vapply(recs, `[[`, character(1L), "status")
  )

  ord <- switch(
    pool$strategy,
    uncertainty = order(-tbl$uncertainty_score),
    fifo = seq_len(nrow(tbl)),
    random = sample(seq_len(nrow(tbl)))
  )
  tbl <- tbl[ord, , drop = FALSE]
  utils::head(tbl, as.integer(n))
}

#' Submit a Completed Annotation Label to the Active Learning Pool
#'
#' Requires `"active_learning_submit"` capability (`annotator`).
#'
#' @param pool A `"dicom_active_learning_pool"` object.
#' @param principal Authenticated `"dicom_server_principal"`.
#' @param candidate_id Candidate identifier from [active_learning_add_candidate()].
#' @param label_path Optional path to saved segmentation/label file.
#' @param quality_score Optional numeric self-reported quality score.
#'
#' @return Updated candidate record list.
#' @export
active_learning_submit <- function(pool,
                                   principal,
                                   candidate_id,
                                   label_path = NULL,
                                   quality_score = NA_real_) {
  srv_check_scalar_chr(candidate_id, "candidate_id")
  if (!exists(candidate_id, envir = pool$candidates, inherits = FALSE)) {
    cli::cli_abort("Candidate {.val {candidate_id}} not found.")
  }
  rec <- get(candidate_id, envir = pool$candidates, inherits = FALSE)
  check_permission(principal, "active_learning_submit", project_id = rec$project_id, throw = TRUE)

  rec$status <- "labeled"
  rec$label_path <- label_path %||% NA_character_
  rec$quality_score <- as.numeric(quality_score)
  rec$labeled_by <- principal$user_id
  assign(candidate_id, rec, envir = pool$candidates)

  if (!is.null(pool$logger)) {
    audit_append(
      pool$logger,
      actor = principal$user_id,
      action = "active_learning_submit",
      project_id = rec$project_id,
      details = list(candidate_id = candidate_id, label_path = rec$label_path)
    )
  }
  rec
}
