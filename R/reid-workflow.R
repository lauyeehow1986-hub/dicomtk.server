#' Request Two-Person Re-Identification of a Pseudonymized Study
#'
#' Requires `"reid_request"` capability (`pi`, `coordinator`, or
#' `honest_broker`). Records a pending re-identification request inside the
#' walled honest-broker enclave.
#'
#' @param enclave A `"dicom_broker_enclave"` object.
#' @param principal Authenticated `"dicom_server_principal"`.
#' @param project_id Project identifier matching the pseudonymized study.
#' @param pseudonym_id Pseudonym identifier recorded in the enclave crosswalk.
#' @param reason Clinical or regulatory justification string.
#' @param ttl_seconds Time-to-live in seconds once both approvals complete
#'   (default `3600L`).
#'
#' @return A list describing the pending re-identification request.
#' @export
reid_request <- function(enclave,
                         principal,
                         project_id,
                         pseudonym_id,
                         reason,
                         ttl_seconds = 3600L) {
  check_permission(principal, "reid_request", project_id = project_id, throw = TRUE)
  srv_check_scalar_chr(pseudonym_id, "pseudonym_id")
  srv_check_scalar_chr(reason, "reason")
  priv <- .broker_priv(enclave)

  if (!exists(pseudonym_id, envir = priv$crosswalk, inherits = FALSE)) {
    cli::cli_abort("Pseudonym {.val {pseudonym_id}} not found in enclave crosswalk.")
  }

  req_id <- paste0("reid_", substr(srv_hash_hex(paste0(pseudonym_id, Sys.time(), stats::runif(1L))), 1L, 12L))
  req <- list(
    request_id = req_id,
    project_id = project_id,
    pseudonym_id = pseudonym_id,
    reason = reason,
    requested_by = principal$user_id,
    requested_at = Sys.time(),
    ttl_seconds = as.numeric(ttl_seconds),
    status = "pending",
    broker_approved_by = NULL,
    dpo_approved_by = NULL,
    approved_at = NULL,
    expires_at = NULL
  )
  assign(req_id, req, envir = priv$reid_requests)

  audit_append(
    priv$logger,
    actor = principal$user_id,
    action = "reid_request",
    project_id = project_id,
    details = list(request_id = req_id, pseudonym_id = pseudonym_id, reason = reason)
  )
  req
}

#' Approve a Re-Identification Request (Two-Person Broker + DPO Rule)
#'
#' Requires both an `honest_broker` (`"reid_approve_broker"`) and a distinct
#' `dpo` (`"reid_approve_dpo"`) principal to approve before disclosure is
#' unlocked.
#'
#' @param enclave A `"dicom_broker_enclave"` object.
#' @param principal Authenticated `"dicom_server_principal"` with `honest_broker`
#'   or `dpo` role.
#' @param request_id Request identifier returned by [reid_request()].
#'
#' @return Updated re-identification request list.
#' @export
reid_approve <- function(enclave, principal, request_id) {
  srv_check_scalar_chr(request_id, "request_id")
  priv <- .broker_priv(enclave)
  if (!exists(request_id, envir = priv$reid_requests, inherits = FALSE)) {
    cli::cli_abort("Re-identification request {.val {request_id}} not found.")
  }
  req <- get(request_id, envir = priv$reid_requests, inherits = FALSE)

  can_broker <- check_permission(principal, "reid_approve_broker", throw = FALSE)
  can_dpo <- check_permission(principal, "reid_approve_dpo", throw = FALSE)
  if (!can_broker && !can_dpo) {
    check_permission(principal, "reid_approve_broker", throw = TRUE)
  }

  if (req$status == "pending") {
    if (can_broker) {
      req$broker_approved_by <- principal$user_id
      req$status <- "partial_broker"
    } else {
      req$dpo_approved_by <- principal$user_id
      req$status <- "partial_dpo"
    }
  } else if (req$status == "partial_broker") {
    if (!can_dpo) {
      cli::cli_abort("Second approval must come from a DPO principal.")
    }
    if (identical(principal$user_id, req$broker_approved_by)) {
      cli::cli_abort("Two-person rule requires a distinct DPO user_id from the honest_broker approver.")
    }
    req$dpo_approved_by <- principal$user_id
    req$approved_at <- Sys.time()
    req$expires_at <- req$approved_at + req$ttl_seconds
    req$status <- "approved"
  } else if (req$status == "partial_dpo") {
    if (!can_broker) {
      cli::cli_abort("Second approval must come from an honest_broker principal.")
    }
    if (identical(principal$user_id, req$dpo_approved_by)) {
      cli::cli_abort("Two-person rule requires a distinct honest_broker user_id from the DPO approver.")
    }
    req$broker_approved_by <- principal$user_id
    req$approved_at <- Sys.time()
    req$expires_at <- req$approved_at + req$ttl_seconds
    req$status <- "approved"
  } else {
    cli::cli_abort("Request {.val {request_id}} is already in status {.val {req$status}}.")
  }

  assign(request_id, req, envir = priv$reid_requests)
  audit_append(
    priv$logger,
    actor = principal$user_id,
    action = "reid_approve",
    project_id = req$project_id,
    details = list(request_id = request_id, status = req$status)
  )
  req
}

#' Disclose Original Patient Identity for an Approved Re-Identification Request
#'
#' Requires `"reid_disclose"` capability (`honest_broker`), completed
#' two-person approval, and an unexpired TTL window.
#'
#' @param enclave A `"dicom_broker_enclave"` object.
#' @param principal Authenticated `"dicom_server_principal"` with
#'   `honest_broker` role.
#' @param request_id Request identifier returned by [reid_request()].
#'
#' @return A list containing `original_patient_id`, `pseudonym_id`, `study_uid`,
#'   and `expires_at`.
#' @export
reid_disclose <- function(enclave, principal, request_id) {
  check_permission(principal, "reid_disclose", throw = TRUE)
  srv_check_scalar_chr(request_id, "request_id")
  priv <- .broker_priv(enclave)
  if (!exists(request_id, envir = priv$reid_requests, inherits = FALSE)) {
    cli::cli_abort("Re-identification request {.val {request_id}} not found.")
  }
  req <- get(request_id, envir = priv$reid_requests, inherits = FALSE)

  if (!identical(req$status, "approved")) {
    cli::cli_abort("Re-identification request {.val {request_id}} is not approved (current status: {.val {req$status}}).")
  }
  if (Sys.time() > req$expires_at) {
    req$status <- "expired"
    assign(request_id, req, envir = priv$reid_requests)
    cli::cli_abort("Re-identification request {.val {request_id}} has expired.")
  }

  cw <- get(req$pseudonym_id, envir = priv$crosswalk, inherits = FALSE)
  audit_append(
    priv$logger,
    actor = principal$user_id,
    action = "reid_disclose",
    project_id = req$project_id,
    details = list(request_id = request_id, pseudonym_id = req$pseudonym_id)
  )

  list(
    request_id = req$request_id,
    project_id = req$project_id,
    pseudonym_id = req$pseudonym_id,
    original_patient_id = cw$original_patient_id,
    study_uid = cw$study_uid,
    expires_at = format(req$expires_at, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  )
}
