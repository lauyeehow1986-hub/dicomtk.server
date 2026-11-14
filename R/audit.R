#' Create or Open a Hash-Chained JSONL Audit Logger
#'
#' Initializes a tamper-evident JSON Lines (`.jsonl`) audit log where each
#' appended entry commits to the cryptographic hash of the previous entry
#' (`prev_hash` -> `entry_hash`).
#'
#' @param log_path Path to the `.jsonl` audit log file.
#' @return An S3 `"dicom_audit_logger"` object.
#' @examples
#' lp <- tempfile(fileext = ".jsonl")
#' on.exit(unlink(lp), add = TRUE)
#' lg <- audit_logger(lp)
#' audit_append(lg, actor = "coord_1", action = "deid_ingest", project_id = "p1")
#' audit_verify(lg)$passed
#' @export
audit_logger <- function(log_path = tempfile("dicomtk_audit_", fileext = ".jsonl")) {
  srv_check_scalar_chr(log_path, "log_path")
  dir.create(dirname(log_path), recursive = TRUE, showWarnings = FALSE)
  if (!file.exists(log_path)) {
    file.create(log_path)
  }
  structure(
    list(log_path = normalizePath(log_path, winslash = "/", mustWork = FALSE)),
    class = "dicom_audit_logger"
  )
}

#' Append a Tamper-Evident Entry to the Hash-Chained Audit Log
#'
#' @param logger A `"dicom_audit_logger"` object from [audit_logger()].
#' @param actor Character user/principal identifier.
#' @param action Character action name (e.g., `"deid_ingest"`, `"reid_disclose"`).
#' @param project_id Optional project identifier string.
#' @param details Optional named list of structured event metadata.
#' @return The appended audit record list (including `prev_hash` and `entry_hash`).
#' @export
audit_append <- function(logger, actor, action, project_id = NULL, details = list()) {
  if (!inherits(logger, "dicom_audit_logger")) {
    cli::cli_abort("{.arg logger} must be a {.cls dicom_audit_logger} object.")
  }
  srv_check_scalar_chr(actor, "actor")
  srv_check_scalar_chr(action, "action")

  existing <- if (file.exists(logger$log_path)) {
    lines <- readLines(logger$log_path, warn = FALSE)
    lines[nzchar(trimws(lines))]
  } else {
    character(0)
  }

  prev_hash <- if (length(existing) == 0L) {
    paste(rep("0", 64L), collapse = "")
  } else {
    last_rec <- jsonlite::fromJSON(existing[length(existing)], simplifyVector = FALSE)
    as.character(last_rec$entry_hash)
  }

  payload <- list(
    seq = as.integer(length(existing) + 1L),
    timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    actor = as.character(actor),
    action = as.character(action),
    project_id = project_id %||% NA_character_,
    details = details,
    prev_hash = prev_hash
  )
  canonical <- as.character(jsonlite::toJSON(payload, auto_unbox = TRUE))
  payload$entry_hash <- srv_hash_hex(paste0(prev_hash, "|", canonical))

  line <- as.character(jsonlite::toJSON(payload, auto_unbox = TRUE))
  cat(line, "\n", sep = "", file = logger$log_path, append = TRUE)
  payload
}

#' Verify Cryptographic Continuity of a Hash-Chained Audit Log
#'
#' @param logger A `"dicom_audit_logger"` object from [audit_logger()].
#' @return A list with `passed` (logical), `n_entries` (integer), and
#'   `corrupted_line` (`NA_integer_` if valid, or 1-based line index of first failure).
#' @export
audit_verify <- function(logger) {
  if (!inherits(logger, "dicom_audit_logger")) {
    cli::cli_abort("{.arg logger} must be a {.cls dicom_audit_logger} object.")
  }
  if (!file.exists(logger$log_path)) {
    return(list(passed = TRUE, n_entries = 0L, corrupted_line = NA_integer_))
  }
  lines <- readLines(logger$log_path, warn = FALSE)
  lines <- lines[nzchar(trimws(lines))]
  if (length(lines) == 0L) {
    return(list(passed = TRUE, n_entries = 0L, corrupted_line = NA_integer_))
  }

  expected_prev <- paste(rep("0", 64L), collapse = "")
  for (i in seq_along(lines)) {
    rec <- tryCatch(jsonlite::fromJSON(lines[i], simplifyVector = FALSE), error = function(e) NULL)
    if (!is.list(rec) || is.null(rec$entry_hash) || !identical(as.character(rec$prev_hash), expected_prev)) {
      return(list(passed = FALSE, n_entries = length(lines), corrupted_line = as.integer(i)))
    }
    recorded_hash <- as.character(rec$entry_hash)
    rec$entry_hash <- NULL
    canonical <- as.character(jsonlite::toJSON(rec, auto_unbox = TRUE))
    computed <- srv_hash_hex(paste0(expected_prev, "|", canonical))
    if (!identical(computed, recorded_hash)) {
      return(list(passed = FALSE, n_entries = length(lines), corrupted_line = as.integer(i)))
    }
    expected_prev <- recorded_hash
  }

  list(passed = TRUE, n_entries = length(lines), corrupted_line = NA_integer_)
}
