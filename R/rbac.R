# Internal: base64url encode/decode in pure R (zero external dependency)
.b64_alphabet <- c(LETTERS, letters, as.character(0:9), "+", "/")

.b64url_encode <- function(raw_bytes) {
  if (is.character(raw_bytes)) raw_bytes <- charToRaw(raw_bytes)
  vals <- as.integer(raw_bytes)
  n <- length(vals)
  if (n == 0L) return("")
  out <- character(0)
  i <- 1L
  while (i <= n) {
    b1 <- vals[i]
    b2 <- if (i + 1L <= n) vals[i + 1L] else 0L
    b3 <- if (i + 2L <= n) vals[i + 2L] else 0L
    triple <- bitwShiftL(b1, 16L) + bitwShiftL(b2, 8L) + b3
    c1 <- .b64_alphabet[bitwAnd(bitwShiftR(triple, 18L), 63L) + 1L]
    c2 <- .b64_alphabet[bitwAnd(bitwShiftR(triple, 12L), 63L) + 1L]
    c3 <- if (i + 1L <= n) .b64_alphabet[bitwAnd(bitwShiftR(triple, 6L), 63L) + 1L] else ""
    c4 <- if (i + 2L <= n) .b64_alphabet[bitwAnd(triple, 63L) + 1L] else ""
    out <- c(out, c1, c2, c3, c4)
    i <- i + 3L
  }
  txt <- paste0(out, collapse = "")
  txt <- gsub("+", "-", txt, fixed = TRUE)
  gsub("/", "_", txt, fixed = TRUE)
}

.b64url_decode <- function(txt) {
  s <- gsub("-", "+", txt, fixed = TRUE)
  s <- gsub("_", "/", s, fixed = TRUE)
  chars <- strsplit(s, "", fixed = TRUE)[[1L]]
  chars <- chars[chars != "="]
  idx <- match(chars, .b64_alphabet) - 1L
  if (any(is.na(idx))) cli::cli_abort("Invalid base64url payload.")
  n <- length(idx)
  out <- integer(0)
  i <- 1L
  while (i <= n) {
    a <- idx[i]
    b <- if (i + 1L <= n) idx[i + 1L] else 0L
    c <- if (i + 2L <= n) idx[i + 2L] else NA_integer_
    d <- if (i + 3L <= n) idx[i + 3L] else NA_integer_
    out <- c(out, bitwOr(bitwShiftL(a, 2L), bitwShiftR(b, 4L)))
    if (!is.na(c)) out <- c(out, bitwOr(bitwShiftL(bitwAnd(b, 15L), 4L), bitwShiftR(c, 2L)))
    if (!is.na(d)) out <- c(out, bitwOr(bitwShiftL(bitwAnd(c, 3L), 6L), d))
    i <- i + 4L
  }
  rawToChar(as.raw(out))
}

#' List Standard `dicomtk.server` RBAC Roles
#'
#' @return Character vector of the 8 standard server roles.
#' @examples
#' server_roles()
#' @export
server_roles <- function() {
  c("pi", "coordinator", "annotator", "auditor", "admin", "site_admin", "honest_broker", "dpo")
}

.srv_role_permissions <- list(
  pi = c("project_read", "study_read", "reid_request", "qa_review", "job_submit"),
  coordinator = c("project_read", "study_read", "deid_ingest", "reid_request", "job_submit", "routing_run"),
  annotator = c("project_read", "study_read", "qa_review", "active_learning_submit"),
  auditor = c("project_read", "audit_read"),
  admin = c("project_create", "project_read", "study_read", "deid_ingest", "qa_review", "audit_read", "job_submit", "routing_run"),
  site_admin = c("project_read", "federation_approve", "audit_read"),
  honest_broker = c("project_read", "deid_ingest", "reid_request", "reid_approve_broker", "reid_disclose", "audit_read", "routing_run"),
  dpo = c("project_read", "reid_approve_dpo", "audit_read")
)

#' Construct an Authenticated Server Principal
#'
#' @param user_id Unique user identifier string.
#' @param roles Character vector of roles from [server_roles()].
#' @param project_ids Character vector of authorized project IDs (or `"*"` for all).
#' @return An S3 `"dicom_server_principal"` object.
#' @export
server_principal <- function(user_id, roles, project_ids = "*") {
  srv_check_scalar_chr(user_id, "user_id")
  roles <- unique(as.character(roles))
  bad <- setdiff(roles, server_roles())
  if (length(bad) > 0L) {
    cli::cli_abort("Unknown role(s): {.val {bad}}.")
  }
  structure(
    list(
      user_id = as.character(user_id),
      roles = roles,
      project_ids = as.character(project_ids)
    ),
    class = "dicom_server_principal"
  )
}

#' Check Role-Based Access Permission for a Principal
#'
#' @param principal A `"dicom_server_principal"` from [server_principal()].
#' @param action Action capability string (e.g., `"reid_approve_broker"`).
#' @param project_id Optional project ID to check project-level scope.
#' @param throw Logical. Abort with permission error if unauthorized (`TRUE`).
#' @return Logical `TRUE` if authorized, `FALSE` otherwise (when `throw = FALSE`).
#' @export
check_permission <- function(principal, action, project_id = NULL, throw = TRUE) {
  if (!inherits(principal, "dicom_server_principal")) {
    if (isTRUE(throw)) cli::cli_abort("Authentication required: invalid principal.")
    return(FALSE)
  }
  allowed_actions <- unique(unlist(.srv_role_permissions[principal$roles], use.names = FALSE))
  has_cap <- action %in% allowed_actions
  in_proj <- is.null(project_id) || ("*" %in% principal$project_ids) || (project_id %in% principal$project_ids)
  ok <- isTRUE(has_cap && in_proj)

  if (!ok && isTRUE(throw)) {
    cli::cli_abort("Permission denied for user {.val {principal$user_id}} on action {.val {action}}.")
  }
  ok
}

#' Mint a Signed Local Test OIDC JWT Token
#'
#' @param user_id Subject user ID (`sub` claim).
#' @param roles Character vector of Keycloak `realm_access$roles`.
#' @param project_ids Character vector of authorized project IDs.
#' @param secret HMAC signing secret.
#' @param expires_in Expiration offset in seconds (default `3600`).
#' @return A signed compact JWT string (`header.payload.signature`).
#' @export
mint_test_jwt <- function(user_id,
                          roles,
                          project_ids = "*",
                          secret = "dicomtk-test-secret",
                          expires_in = 3600) {
  hdr <- .b64url_encode(as.character(jsonlite::toJSON(list(alg = "HS256", typ = "JWT"), auto_unbox = TRUE)))
  now <- as.numeric(Sys.time())
  claims <- list(
    sub = as.character(user_id),
    realm_access = list(roles = as.list(as.character(roles))),
    project_ids = as.list(as.character(project_ids)),
    iat = floor(now),
    exp = floor(now + expires_in)
  )
  pay <- .b64url_encode(as.character(jsonlite::toJSON(claims, auto_unbox = TRUE)))
  sig <- srv_hmac_hex(secret, paste0(hdr, ".", pay))
  paste0(hdr, ".", pay, ".", sig)
}

#' Verify an OIDC / Keycloak Bearer Token and Return a Server Principal
#'
#' @param token Bearer token string (with or without `"Bearer "` prefix).
#' @param secret HMAC secret for verifying local test JWTs.
#' @param oidc_userinfo_url Optional Keycloak OIDC `/userinfo` endpoint URL.
#' @return A `"dicom_server_principal"` object.
#' @export
verify_bearer_token <- function(token,
                                secret = NULL,
                                oidc_userinfo_url = NULL) {
  srv_check_scalar_chr(token, "token")
  tok <- sub("^Bearer\\s+", "", trimws(token), ignore.case = TRUE)

  if (!is.null(oidc_userinfo_url) && nzchar(oidc_userinfo_url)) {
    resp <- httr2::request(oidc_userinfo_url) |>
      httr2::req_auth_bearer_token(tok) |>
      httr2::req_perform()
    info <- httr2::resp_body_json(resp, simplifyVector = FALSE)
    roles <- unlist(info$realm_access$roles %||% info$roles %||% "pi")
    return(server_principal(
      user_id = as.character(info$sub %||% info$preferred_username),
      roles = intersect(as.character(roles), server_roles())
    ))
  }

  parts <- strsplit(tok, ".", fixed = TRUE)[[1L]]
  if (length(parts) != 3L) {
    cli::cli_abort("Malformed bearer JWT token.")
  }
  expected_sig <- srv_hmac_hex(secret %||% "dicomtk-test-secret", paste0(parts[1L], ".", parts[2L]))
  if (!identical(parts[3L], expected_sig)) {
    cli::cli_abort("Invalid JWT signature.")
  }
  claims <- jsonlite::fromJSON(.b64url_decode(parts[2L]), simplifyVector = FALSE)
  if (!is.null(claims$exp) && as.numeric(Sys.time()) > as.numeric(claims$exp)) {
    cli::cli_abort("JWT token has expired.")
  }
  roles <- unlist(claims$realm_access$roles %||% character(0))
  pids <- unlist(claims$project_ids %||% "*")
  server_principal(user_id = as.character(claims$sub), roles = roles, project_ids = pids)
}
