#' Initialize an Asynchronous or Synchronous Job Queue
#'
#' Creates a job queue supporting synchronous in-process execution (`"sync"`)
#' or non-blocking parallel worker execution via `mirai` (`"mirai"`).
#'
#' @param backend Execution backend: `"sync"` or `"mirai"`.
#' @param workers Number of `mirai` daemon workers when `backend = "mirai"`.
#' @param logger Optional `"dicom_audit_logger"` for job submission auditing.
#'
#' @return An S3 `"dicom_job_queue"` object.
#' @examples
#' q <- job_queue_init(backend = "sync")
#' q$backend
#' @export
job_queue_init <- function(backend = c("sync", "mirai"), workers = 2L, logger = NULL) {
  backend <- match.arg(backend)
  if (identical(backend, "mirai") && !requireNamespace("mirai", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg mirai} is required for {.val mirai} job queue backend.")
  }
  structure(
    list(
      backend = backend,
      workers = as.integer(workers),
      logger = logger,
      jobs = new.env(parent = emptyenv())
    ),
    class = "dicom_job_queue"
  )
}

#' Submit a Job to the Server Job Queue
#'
#' Requires `"job_submit"` permission on `project_id`.
#'
#' @param queue A `"dicom_job_queue"` from [job_queue_init()].
#' @param principal Authenticated `"dicom_server_principal"`.
#' @param project_id Target project identifier.
#' @param fn Function to execute.
#' @param args Named list of arguments passed to `fn`.
#' @param job_type Short job category string (default `"generic"`).
#'
#' @return A list with `job_id`, `project_id`, `job_type`, and `status`.
#' @export
job_submit <- function(queue,
                       principal,
                       project_id,
                       fn,
                       args = list(),
                       job_type = "generic") {
  if (!inherits(queue, "dicom_job_queue")) {
    cli::cli_abort("{.arg queue} must be a {.cls dicom_job_queue} object.")
  }
  check_permission(principal, "job_submit", project_id = project_id, throw = TRUE)
  if (!is.function(fn)) {
    cli::cli_abort("{.arg fn} must be a function.")
  }

  job_id <- paste0("job_", substr(srv_hash_hex(paste0(project_id, job_type, Sys.time(), stats::runif(1L))), 1L, 12L))
  rec <- list(
    job_id = job_id,
    project_id = project_id,
    job_type = as.character(job_type),
    submitted_by = principal$user_id,
    created_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    status = "running",
    mirai_obj = NULL,
    result = NULL,
    error = NULL
  )

  if (identical(queue$backend, "mirai")) {
    rec$mirai_obj <- mirai::mirai(do.call(fn, args), fn = fn, args = args)
  } else {
    res <- tryCatch(
      list(ok = TRUE, val = do.call(fn, args)),
      error = function(e) list(ok = FALSE, err = conditionMessage(e))
    )
    if (res$ok) {
      rec$status <- "completed"
      rec$result <- res$val
    } else {
      rec$status <- "failed"
      rec$error <- res$err
    }
  }

  assign(job_id, rec, envir = queue$jobs)
  if (!is.null(queue$logger)) {
    audit_append(
      queue$logger,
      actor = principal$user_id,
      action = "job_submit",
      project_id = project_id,
      details = list(job_id = job_id, job_type = job_type, status = rec$status)
    )
  }

  list(
    job_id = job_id,
    project_id = project_id,
    job_type = rec$job_type,
    status = rec$status
  )
}

#' Query Job Status
#'
#' @param queue A `"dicom_job_queue"` object.
#' @param job_id Job identifier returned by [job_submit()].
#' @return A list with `job_id`, `project_id`, `job_type`, and `status`.
#' @export
job_status <- function(queue, job_id) {
  srv_check_scalar_chr(job_id, "job_id")
  if (!exists(job_id, envir = queue$jobs, inherits = FALSE)) {
    cli::cli_abort("Job {.val {job_id}} not found.")
  }
  rec <- get(job_id, envir = queue$jobs, inherits = FALSE)
  if (!is.null(rec$mirai_obj) && rec$status == "running") {
    if (!mirai::unresolved(rec$mirai_obj)) {
      val <- rec$mirai_obj$data
      if (mirai::is_error_value(val)) {
        rec$status <- "failed"
        rec$error <- as.character(val)
      } else {
        rec$status <- "completed"
        rec$result <- val
      }
      assign(job_id, rec, envir = queue$jobs)
    }
  }
  list(
    job_id = rec$job_id,
    project_id = rec$project_id,
    job_type = rec$job_type,
    status = rec$status
  )
}

#' Retrieve Job Result
#'
#' @param queue A `"dicom_job_queue"` object.
#' @param job_id Job identifier returned by [job_submit()].
#' @param wait Logical; if `TRUE` and backend is `"mirai"`, blocks until
#'   completion.
#' @return The return value of the submitted job function.
#' @export
job_result <- function(queue, job_id, wait = TRUE) {
  srv_check_scalar_chr(job_id, "job_id")
  if (!exists(job_id, envir = queue$jobs, inherits = FALSE)) {
    cli::cli_abort("Job {.val {job_id}} not found.")
  }
  rec <- get(job_id, envir = queue$jobs, inherits = FALSE)
  if (!is.null(rec$mirai_obj) && rec$status == "running") {
    if (isTRUE(wait)) {
      val <- rec$mirai_obj[]
      if (mirai::is_error_value(val)) {
        rec$status <- "failed"
        rec$error <- as.character(val)
        assign(job_id, rec, envir = queue$jobs)
        cli::cli_abort("Job {.val {job_id}} failed: {rec$error}")
      }
      rec$status <- "completed"
      rec$result <- val
      assign(job_id, rec, envir = queue$jobs)
    } else {
      cli::cli_abort("Job {.val {job_id}} is still running.")
    }
  }
  if (identical(rec$status, "failed")) {
    cli::cli_abort("Job {.val {job_id}} failed: {rec$error}")
  }
  rec$result
}
