#' Check Whether SaMD Clinical Chart Write-Back Is Explicitly Enabled
#'
#' Clinical write-back (`STOW-RS` `SEG`/`SR` + FHIR `DiagnosticReport` +
#' `Provenance`) is disabled by default as a Software as a Medical Device (SaMD)
#' regulatory safeguard. Enable explicitly via
#' `options(dicomtk.server.enable_clinical_writeback = TRUE)` or environment
#' variable `DICOMTK_ENABLE_CLINICAL_WRITEBACK=true`.
#'
#' @return Logical scalar (`TRUE` if enabled, `FALSE` otherwise).
#' @examples
#' clinical_writeback_enabled()
#' @export
clinical_writeback_enabled <- function() {
  opt_on <- isTRUE(getOption("dicomtk.server.enable_clinical_writeback", FALSE))
  env_val <- tolower(trimws(Sys.getenv("DICOMTK_ENABLE_CLINICAL_WRITEBACK", unset = "")))
  env_on <- env_val %in% c("1", "true", "yes")
  opt_on || env_on
}

#' Execute Dual-Gated SaMD Clinical Chart Write-Back
#'
#' Enforces both the server-wide SaMD feature flag
#' ([clinical_writeback_enabled()]) and RBAC `"clinical_writeback"`
#' permission (`pi` or `admin`) before dispatching or simulating `STOW-RS` and
#' FHIR `DiagnosticReport` + `Provenance` write-back, logging every event to
#' the SHA-256 hash-chained audit trail.
#'
#' @param ctx A `"dicom_server_context"` from [server_create_context()].
#' @param principal Authenticated `"dicom_server_principal"`.
#' @param project_id Project identifier.
#' @param air_bundle A `"dicom_ihe_air_bundle"` from [ihe_air_bundle()].
#' @param dicomweb_stow_url Optional DICOMweb `STOW-RS` endpoint URL.
#' @param fhir_base_url Optional FHIR R4/R5 base URL for `DiagnosticReport`
#'   and `Provenance` write-back.
#' @param dry_run Logical; if `TRUE`, validates gates and logs audit entry
#'   without performing external HTTP calls.
#'
#' @return A list with `status`, `study_uid`, `dicom_sop_uid`, and
#'   `audit_seq`.
#' @export
clinical_writeback_execute <- function(ctx,
                                       principal,
                                       project_id,
                                       air_bundle,
                                       dicomweb_stow_url = NULL,
                                       fhir_base_url = NULL,
                                       dry_run = FALSE) {
  if (!inherits(ctx, "dicom_server_context")) {
    cli::cli_abort("{.arg ctx} must be a {.cls dicom_server_context} object.")
  }
  if (!inherits(air_bundle, "dicom_ihe_air_bundle")) {
    cli::cli_abort("{.arg air_bundle} must be a {.cls dicom_ihe_air_bundle} object.")
  }
  if (!clinical_writeback_enabled()) {
    cli::cli_abort("Clinical write-back is disabled by SaMD safeguard; opt in via option {.val dicomtk.server.enable_clinical_writeback} or env {.envvar DICOMTK_ENABLE_CLINICAL_WRITEBACK}.")
  }
  check_permission(principal, "clinical_writeback", project_id = project_id, throw = TRUE)

  rpt_status <- as.character(air_bundle$diagnostic_report$status %||% "preliminary")
  if (identical(rpt_status, "final") && is.null(air_bundle$diagnostic_report$verified_by)) {
    cli::cli_abort("SaMD safeguard: AI DiagnosticReport cannot be written back with status {.val final} without clinician {.field verified_by} sign-off.")
  }

  if (!isTRUE(dry_run) && !is.null(fhir_base_url) && nzchar(fhir_base_url)) {
    base <- sub("/+$", "", fhir_base_url)
    httr2::request(paste0(base, "/DiagnosticReport")) |>
      httr2::req_body_json(air_bundle$diagnostic_report) |>
      httr2::req_perform()
    httr2::request(paste0(base, "/Provenance")) |>
      httr2::req_body_json(air_bundle$provenance) |>
      httr2::req_perform()
  }

  rec <- audit_append(
    ctx$logger,
    actor = principal$user_id,
    action = "clinical_writeback",
    project_id = project_id,
    details = list(
      study_uid = air_bundle$study_uid,
      dicom_artifact_type = air_bundle$dicom_artifact_type,
      dicom_sop_uid = air_bundle$dicom_sop_uid,
      model_name = air_bundle$model_name,
      model_version = air_bundle$model_version,
      dry_run = isTRUE(dry_run)
    )
  )

  list(
    status = if (isTRUE(dry_run)) "dry_run_ok" else "dispatched",
    study_uid = air_bundle$study_uid,
    dicom_sop_uid = air_bundle$dicom_sop_uid,
    audit_seq = rec$seq
  )
}
