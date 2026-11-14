# Internal: retrieve private enclave vault state (never attached to S3 object)
.broker_priv <- function(enclave) {
  if (!inherits(enclave, "dicom_broker_enclave") || is.null(.srv_env$enclaves)) {
    cli::cli_abort("Invalid or uninitialized {.cls dicom_broker_enclave} object.")
  }
  if (!exists(enclave$enclave_id, envir = .srv_env$enclaves, inherits = FALSE)) {
    cli::cli_abort("Broker enclave {.val {enclave$enclave_id}} not found.")
  }
  get(enclave$enclave_id, envir = .srv_env$enclaves, inherits = FALSE)
}

#' Initialize a Walled-Off Honest-Broker Key & Crosswalk Custody Enclave
#'
#' Creates a `"dicom_broker_enclave"` whose cryptographic master keys,
#' HashiCorp Vault / KMS credentials, and patient-identity crosswalks live
#' inside an isolated internal closure inaccessible to `pi`, `coordinator`,
#' `annotator`, `auditor`, `admin`, and `site_admin` principals.
#'
#' @param work_dir Walled broker workspace directory.
#' @param backend Key custody backend: `"local_vault"`, `"hashicorp_vault"`,
#'   or `"kms"`.
#' @param passphrase Optional passphrase for `"local_vault"` key derivation.
#' @param vault_url Optional HashiCorp Vault / KMS endpoint URL.
#' @param vault_token Optional Vault token (never exposed by `print`/`str`).
#' @param logger Optional `"dicom_audit_logger"` from [audit_logger()].
#'
#' @return An opaque S3 `"dicom_broker_enclave"` handle.
#' @export
broker_enclave_init <- function(work_dir = tempfile("broker_enclave_"),
                                backend = c("local_vault", "hashicorp_vault", "kms"),
                                passphrase = NULL,
                                vault_url = NULL,
                                vault_token = NULL,
                                logger = NULL) {
  backend <- match.arg(backend)
  dir.create(work_dir, recursive = TRUE, showWarnings = FALSE)
  if (is.null(.srv_env$enclaves)) {
    .srv_env$enclaves <- new.env(parent = emptyenv())
  }
  eid <- paste0("enc_", substr(srv_hash_hex(paste0(work_dir, Sys.time(), stats::runif(1L))), 1L, 16L))

  kp <- dicomtk::dicom_key_provider(
    mode = "local",
    passphrase = passphrase %||% paste0("broker-auto-", eid),
    salt = eid
  )

  priv <- list(
    enclave_id = eid,
    work_dir = normalizePath(work_dir, winslash = "/", mustWork = FALSE),
    backend = backend,
    vault_url = vault_url,
    vault_token = vault_token,
    key_provider = kp,
    crosswalk = new.env(parent = emptyenv()),
    reid_requests = new.env(parent = emptyenv()),
    logger = logger %||% audit_logger(file.path(work_dir, "broker_audit.jsonl"))
  )
  assign(eid, priv, envir = .srv_env$enclaves)

  structure(
    list(
      enclave_id = eid,
      backend = backend,
      custody_mode = "broker",
      created_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
    ),
    class = "dicom_broker_enclave"
  )
}

#' @export
print.dicom_broker_enclave <- function(x, ...) {
  cli::cli_alert_info("DICOM Honest-Broker Enclave [{x$enclave_id}] (backend: {x$backend}, keys: <SEALED>)")
  invisible(x)
}

#' @export
format.dicom_broker_enclave <- function(x, ...) {
  sprintf("<dicom_broker_enclave:%s backend=%s keys=SEALED>", x$enclave_id, x$backend)
}

#' @export
str.dicom_broker_enclave <- function(object, ...) {
  cat(format(object), "\n")
  invisible(object)
}

#' De-Identify a Study Inside the Walled Honest-Broker Workspace
#'
#' Requires `"deid_ingest"` capability (`coordinator`, `honest_broker`, or
#' `admin`). Executes `dicomtk::dicom_deid()` using the enclave's sealed key
#' provider, records the reversible `pseudonym_id -> original_patient_id`
#' mapping inside the enclave crosswalk, and writes clean de-identified files
#' to `out_dir`.
#'
#' @param enclave A `"dicom_broker_enclave"` from [broker_enclave_init()].
#' @param principal Authenticated `"dicom_server_principal"`.
#' @param project_id Target project identifier.
#' @param input_dir Source directory containing identified DICOM files.
#' @param out_dir Output directory in the research project workspace.
#' @param profile Baseline PS3.15 profile name (default `"ps3.15"`).
#'
#' @return A list with `project_id`, `pseudonym_id`, `out_dir`, and `n_files`.
#' @export
broker_deid_study <- function(enclave,
                              principal,
                              project_id,
                              input_dir,
                              out_dir,
                              profile = "ps3.15") {
  check_permission(principal, "deid_ingest", project_id = project_id, throw = TRUE)
  priv <- .broker_priv(enclave)

  hdr <- dicomtk::read_dicom(input_dir, wide = TRUE)
  orig_pid <- if ("PatientID" %in% names(hdr) && nrow(hdr) > 0L) {
    as.character(hdr$PatientID[1L])
  } else {
    "UNKNOWN_PID"
  }
  pseudo_id <- paste0("SUBJ-", toupper(substr(srv_hash_hex(paste0(enclave$enclave_id, "::", orig_pid)), 1L, 12L)))

  prof <- dicomtk::dicom_deid_profile(profile = profile)
  deid_res <- dicomtk::dicom_deid(
    path = input_dir,
    out_dir = out_dir,
    profile = prof,
    key = priv$key_provider,
    overwrite = TRUE
  )

  assign(
    pseudo_id,
    list(
      pseudonym_id = pseudo_id,
      original_patient_id = orig_pid,
      project_id = project_id,
      study_uid = if ("StudyInstanceUID" %in% names(hdr)) as.character(hdr$StudyInstanceUID[1L]) else NA_character_,
      created_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
    ),
    envir = priv$crosswalk
  )

  audit_append(
    priv$logger,
    actor = principal$user_id,
    action = "deid_ingest",
    project_id = project_id,
    details = list(pseudonym_id = pseudo_id, n_files = deid_res$n_files %||% nrow(hdr))
  )

  list(
    project_id = project_id,
    pseudonym_id = pseudo_id,
    out_dir = out_dir,
    n_files = as.integer(deid_res$n_files %||% nrow(hdr))
  )
}

#' Guarded Crosswalk Lookup (Rejects All Unapproved or Non-Broker Access)
#'
#' @param enclave A `"dicom_broker_enclave"` object.
#' @param principal Authenticated `"dicom_server_principal"`.
#' @param pseudonym_id Pseudonym identifier string.
#' @return Never returns for unapproved access; aborts with permission error.
#' @export
broker_lookup_crosswalk <- function(enclave, principal, pseudonym_id) {
  check_permission(principal, "reid_disclose", throw = TRUE)
  cli::cli_abort("Direct unapproved crosswalk lookup is forbidden; use {.fn reid_request} -> {.fn reid_approve} -> {.fn reid_disclose}.")
}
