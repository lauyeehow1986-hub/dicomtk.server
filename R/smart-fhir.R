.hex_to_raw <- function(hex_str) {
  starts <- seq(1L, nchar(hex_str), by = 2L)
  pairs <- substring(hex_str, starts, starts + 1L)
  as.raw(strtoi(pairs, base = 16L))
}

#' Discover SMART on FHIR v2 Configuration
#'
#' Queries `<fhir_base_url>/.well-known/smart-configuration` (or validates a
#' supplied `mock_config` list) and verifies that `"S256"` PKCE is supported.
#'
#' @param fhir_base_url Base URL of the FHIR R4/R5 server.
#' @param mock_config Optional named list for offline/unit testing.
#'
#' @return A list with `fhir_base_url`, `authorization_endpoint`,
#'   `token_endpoint`, and `code_challenge_methods_supported`.
#' @examples
#' cfg <- smart_discover_config(
#'   "https://fhir.example.org/r4",
#'   mock_config = list(
#'     authorization_endpoint = "https://auth.example.org/authorize",
#'     token_endpoint = "https://auth.example.org/token",
#'     code_challenge_methods_supported = "S256"
#'   )
#' )
#' cfg$authorization_endpoint
#' @export
smart_discover_config <- function(fhir_base_url, mock_config = NULL) {
  srv_check_scalar_chr(fhir_base_url, "fhir_base_url")
  base <- sub("/+$", "", fhir_base_url)

  cfg <- if (!is.null(mock_config)) {
    mock_config
  } else {
    resp <- httr2::request(paste0(base, "/.well-known/smart-configuration")) |>
      httr2::req_headers(Accept = "application/json") |>
      httr2::req_perform()
    httr2::resp_body_json(resp, simplifyVector = TRUE)
  }

  if (is.null(cfg$authorization_endpoint) || is.null(cfg$token_endpoint)) {
    cli::cli_abort("SMART configuration missing authorization_endpoint or token_endpoint.")
  }
  methods <- as.character(cfg$code_challenge_methods_supported %||% character(0))
  if (length(methods) > 0L && !("S256" %in% methods)) {
    cli::cli_abort("SMART authorization server does not advertise S256 PKCE support.")
  }

  list(
    fhir_base_url = base,
    authorization_endpoint = as.character(cfg$authorization_endpoint),
    token_endpoint = as.character(cfg$token_endpoint),
    code_challenge_methods_supported = methods
  )
}

#' Generate an RFC 7636 S256 PKCE Verifier and Challenge Pair
#'
#' @param verifier Optional PKCE `code_verifier` (43-128 URL-safe characters).
#'   If `NULL`, a high-entropy 64-character verifier is generated.
#'
#' @return A list with `code_verifier`, `code_challenge`, and
#'   `code_challenge_method = "S256"`.
#' @examples
#' pkce <- smart_pkce_challenge()
#' pkce$code_challenge_method
#' @export
smart_pkce_challenge <- function(verifier = NULL) {
  if (is.null(verifier)) {
    raw_bytes <- as.raw(sample(0:255, 48L, replace = TRUE))
    verifier <- .b64url_encode(raw_bytes)
  }
  srv_check_scalar_chr(verifier, "verifier")
  if (nchar(verifier) < 43L || nchar(verifier) > 128L) {
    cli::cli_abort("RFC 7636 {.arg verifier} must be between 43 and 128 characters.")
  }
  digest_hex <- srv_hash_hex(verifier)
  challenge <- .b64url_encode(.hex_to_raw(digest_hex))
  list(
    code_verifier = verifier,
    code_challenge = challenge,
    code_challenge_method = "S256"
  )
}

#' Build a SMART on FHIR v2 EHR-Launch Authorization URL
#'
#' @param config SMART configuration list from [smart_discover_config()].
#' @param client_id Registered OAuth2 client identifier.
#' @param redirect_uri Callback redirect URI.
#' @param launch Optional EHR launch context token.
#' @param scopes Character vector of SMART v2 scopes.
#' @param state Optional CSRF state token (auto-generated if `NULL`).
#' @param pkce PKCE challenge list from [smart_pkce_challenge()].
#'
#' @return A list with `url`, `state`, and `pkce`.
#' @export
smart_build_auth_url <- function(config,
                                 client_id,
                                 redirect_uri,
                                 launch = NULL,
                                 scopes = c(
                                   "launch", "openid", "fhirUser",
                                   "patient/Patient.rs",
                                   "patient/ImagingStudy.rs",
                                   "patient/DiagnosticReport.rs"
                                 ),
                                 state = NULL,
                                 pkce = smart_pkce_challenge()) {
  srv_check_scalar_chr(client_id, "client_id")
  srv_check_scalar_chr(redirect_uri, "redirect_uri")
  if (is.null(state)) {
    state <- substr(srv_hash_hex(paste0(client_id, Sys.time(), stats::runif(1L))), 1L, 24L)
  }
  params <- list(
    response_type = "code",
    client_id = client_id,
    redirect_uri = redirect_uri,
    scope = paste(scopes, collapse = " "),
    state = state,
    aud = config$fhir_base_url,
    code_challenge = pkce$code_challenge,
    code_challenge_method = "S256"
  )
  if (!is.null(launch) && nzchar(launch)) {
    params$launch <- launch
  }
  enc <- vapply(names(params), function(nm) {
    paste0(utils::URLencode(nm, reserved = TRUE), "=", utils::URLencode(as.character(params[[nm]]), reserved = TRUE))
  }, character(1L))
  url <- paste0(config$authorization_endpoint, "?", paste(enc, collapse = "&"))
  list(url = url, state = state, pkce = pkce)
}

#' Exchange a SMART Authorization Code for a Patient-Context Session
#'
#' Verifies CSRF `state` equality and RFC 7636 `code_verifier` length before
#' exchanging the authorization code at `config$token_endpoint`.
#'
#' @param config SMART configuration list from [smart_discover_config()].
#' @param code Authorization code received at `redirect_uri`.
#' @param redirect_uri Callback redirect URI.
#' @param client_id Registered OAuth2 client identifier.
#' @param code_verifier PKCE `code_verifier` matching the `code_challenge`.
#' @param expected_state Expected CSRF `state` generated in
#'   [smart_build_auth_url()].
#' @param received_state `state` query parameter returned by the auth server.
#' @param mock_response Optional named list for offline/unit testing.
#'
#' @return An S3 `"dicom_smart_session"` object.
#' @export
smart_exchange_token <- function(config,
                                 code,
                                 redirect_uri,
                                 client_id,
                                 code_verifier,
                                 expected_state = NULL,
                                 received_state = NULL,
                                 mock_response = NULL) {
  srv_check_scalar_chr(code, "code")
  srv_check_scalar_chr(code_verifier, "code_verifier")
  if (nchar(code_verifier) < 43L) {
    cli::cli_abort("Invalid PKCE {.arg code_verifier} length.")
  }
  if (!is.null(expected_state) && !identical(as.character(expected_state), as.character(received_state))) {
    cli::cli_abort("CSRF state mismatch during SMART token exchange.")
  }

  tok <- if (!is.null(mock_response)) {
    mock_response
  } else {
    resp <- httr2::request(config$token_endpoint) |>
      httr2::req_body_form(
        grant_type = "authorization_code",
        code = code,
        redirect_uri = redirect_uri,
        client_id = client_id,
        code_verifier = code_verifier
      ) |>
      httr2::req_perform()
    httr2::resp_body_json(resp, simplifyVector = FALSE)
  }

  structure(
    list(
      fhir_base_url = config$fhir_base_url,
      access_token = as.character(tok$access_token %||% ""),
      patient_id = as.character(tok$patient %||% NA_character_),
      encounter_id = as.character(tok$encounter %||% NA_character_),
      fhir_user = as.character(tok$fhirUser %||% NA_character_),
      scope = as.character(tok$scope %||% "")
    ),
    class = "dicom_smart_session"
  )
}

#' Pull Patient-Context FHIR Resources into the Honest-Broker Enclave
#'
#' Requires `"deid_ingest"` permission (`coordinator`, `honest_broker`, or
#' `admin`). Pseudonymizes the EHR `patient_id` inside the walled enclave
#' crosswalk and returns only de-identified imaging/report counts and UIDs.
#'
#' @param session A `"dicom_smart_session"` from [smart_exchange_token()].
#' @param enclave A `"dicom_broker_enclave"` from [broker_enclave_init()].
#' @param principal Authenticated `"dicom_server_principal"`.
#' @param project_id Target project identifier.
#' @param fhir_bundle Optional parsed FHIR Bundle list for offline testing.
#'
#' @return A de-identified summary list containing `project_id`,
#'   `pseudonym_id`, `n_imaging_studies`, `n_diagnostic_reports`, and
#'   `study_uids`.
#' @export
smart_pull_patient_context <- function(session,
                                       enclave,
                                       principal,
                                       project_id,
                                       fhir_bundle = NULL) {
  if (!inherits(session, "dicom_smart_session")) {
    cli::cli_abort("{.arg session} must be a {.cls dicom_smart_session} object.")
  }
  check_permission(principal, "deid_ingest", project_id = project_id, throw = TRUE)
  priv <- .broker_priv(enclave)

  bundle <- if (!is.null(fhir_bundle)) {
    fhir_bundle
  } else {
    resp <- httr2::request(paste0(session$fhir_base_url, "/Patient/", session$patient_id, "/$everything")) |>
      httr2::req_auth_bearer_token(session$access_token) |>
      httr2::req_headers(Accept = "application/fhir+json") |>
      httr2::req_perform()
    httr2::resp_body_json(resp, simplifyVector = FALSE)
  }

  entries <- bundle$entry %||% list()
  resources <- lapply(entries, function(e) e$resource)
  img_studies <- Filter(function(r) identical(r$resourceType, "ImagingStudy"), resources)
  diag_reports <- Filter(function(r) identical(r$resourceType, "DiagnosticReport"), resources)

  study_uids <- unlist(lapply(img_studies, function(s) {
    ids <- s$identifier %||% list()
    if (length(ids) > 0L) sub("^urn:oid:", "", as.character(ids[[1L]]$value %||% "")) else character(0)
  }))

  orig_pid <- as.character(session$patient_id)
  pseudo_id <- paste0("SUBJ-", toupper(substr(srv_hash_hex(paste0(enclave$enclave_id, "::", orig_pid)), 1L, 12L)))

  assign(
    pseudo_id,
    list(
      pseudonym_id = pseudo_id,
      original_patient_id = orig_pid,
      project_id = project_id,
      study_uid = if (length(study_uids) > 0L) study_uids[1L] else NA_character_,
      created_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
    ),
    envir = priv$crosswalk
  )

  audit_append(
    priv$logger,
    actor = principal$user_id,
    action = "smart_context_pull",
    project_id = project_id,
    details = list(pseudonym_id = pseudo_id, n_imaging_studies = length(img_studies), n_diagnostic_reports = length(diag_reports))
  )

  list(
    project_id = project_id,
    pseudonym_id = pseudo_id,
    n_imaging_studies = length(img_studies),
    n_diagnostic_reports = length(diag_reports),
    study_uids = as.character(study_uids)
  )
}
