#' Create a Multi-User `dicomtk.server` Runtime Context
#'
#' Bundles the project registry, SHA-256 hash-chained audit logger, walled-off
#' honest-broker custody enclave, job queue, QA review queue, and active
#' learning pool into a single server context.
#'
#' @param work_dir Base directory for server state and audit logs.
#' @param jwt_secret Secret key for HS256 JWT verification.
#' @param enclave_passphrase Optional passphrase for the honest-broker enclave.
#'
#' @return An S3 `"dicom_server_context"` object.
#' @examples
#' tmp <- tempfile("srv_ctx_")
#' ctx <- server_create_context(work_dir = tmp, jwt_secret = "demo-secret")
#' server_handle_request(ctx, "GET", "/health")
#' unlink(tmp, recursive = TRUE)
#' @export
server_create_context <- function(work_dir = tempfile("dicomtk_srv_"),
                                  jwt_secret = "change-me-in-production",
                                  enclave_passphrase = NULL) {
  dir.create(work_dir, recursive = TRUE, showWarnings = FALSE)
  logger <- audit_logger(file.path(work_dir, "server_audit.jsonl"))
  structure(
    list(
      work_dir = normalizePath(work_dir, winslash = "/", mustWork = FALSE),
      jwt_secret = as.character(jwt_secret),
      logger = logger,
      projects = project_registry_init(),
      enclave = broker_enclave_init(
        work_dir = file.path(work_dir, "enclave"),
        passphrase = enclave_passphrase,
        logger = logger
      ),
      jobs = job_queue_init(backend = "sync", logger = logger),
      qa_queue = qa_queue_init(logger = logger),
      al_pool = active_learning_pool_init(strategy = "uncertainty", logger = logger)
    ),
    class = "dicom_server_context"
  )
}

.extract_bearer <- function(headers) {
  if (length(headers) == 0L) return(NULL)
  nms <- tolower(names(headers))
  idx <- match("authorization", nms)
  if (is.na(idx)) return(NULL)
  val <- as.character(headers[[idx]])
  if (!grepl("^Bearer\\s+", val, ignore.case = TRUE)) return(NULL)
  sub("^Bearer\\s+", "", val, ignore.case = TRUE)
}

#' Dispatch an HTTP-Style Request Against a `dicom_server_context`
#'
#' Provides a pure-R, test-friendly REST dispatcher enforcing JWT authentication
#' and RBAC permissions before delegating to server subsystems.
#'
#' @param ctx A `"dicom_server_context"` from [server_create_context()].
#' @param method HTTP method (`"GET"` or `"POST"`).
#' @param path Request path (e.g. `"/health"`, `"/projects"`, `"/qa"`,
#'   `"/audit/verify"`).
#' @param headers Named list of HTTP headers (including `Authorization`).
#' @param body Named list representing parsed JSON request body.
#'
#' @return A list with `status` (integer HTTP code) and `body` (response list).
#' @export
server_handle_request <- function(ctx,
                                  method = "GET",
                                  path = "/health",
                                  headers = list(),
                                  body = list()) {
  if (!inherits(ctx, "dicom_server_context")) {
    cli::cli_abort("{.arg ctx} must be a {.cls dicom_server_context} object.")
  }
  method <- toupper(as.character(method))

  if (identical(method, "GET") && identical(path, "/health")) {
    return(list(status = 200L, body = list(status = "ok", service = "dicomtk.server", version = "1.0.0")))
  }

  tok <- .extract_bearer(headers)
  if (is.null(tok) || !nzchar(tok)) {
    return(list(status = 401L, body = list(error = "Missing or malformed Bearer token.")))
  }
  principal <- tryCatch(
    verify_bearer_token(tok, secret = ctx$jwt_secret),
    error = function(e) NULL
  )
  if (is.null(principal)) {
    return(list(status = 401L, body = list(error = "Invalid or expired Bearer token.")))
  }

  if (identical(method, "GET") && identical(path, "/projects")) {
    if (!check_permission(principal, "project_read", throw = FALSE)) {
      return(list(status = 403L, body = list(error = "Forbidden: project_read required.")))
    }
    return(list(status = 200L, body = list(projects = project_list(ctx$projects))))
  }

  if (identical(method, "POST") && identical(path, "/projects")) {
    if (!check_permission(principal, "project_create", throw = FALSE)) {
      return(list(status = 403L, body = list(error = "Forbidden: project_create required.")))
    }
    pid <- body$project_id %||% ""
    if (!nzchar(pid)) {
      return(list(status = 400L, body = list(error = "Missing project_id.")))
    }
    proj <- project_create(
      ctx$projects,
      project_id = pid,
      title = body$title %||% pid,
      deid_profile = body$deid_profile %||% "ps3.15",
      custody_mode = body$custody_mode %||% "broker"
    )
    return(list(status = 201L, body = proj))
  }

  if (identical(method, "GET") && identical(path, "/qa")) {
    if (!check_permission(principal, "qa_review", throw = FALSE)) {
      return(list(status = 403L, body = list(error = "Forbidden: qa_review required.")))
    }
    return(list(status = 200L, body = list(items = qa_list(ctx$qa_queue))))
  }

  if (identical(method, "GET") && identical(path, "/audit/verify")) {
    if (!check_permission(principal, "audit_read", throw = FALSE)) {
      return(list(status = 403L, body = list(error = "Forbidden: audit_read required.")))
    }
    return(list(status = 200L, body = audit_verify(ctx$logger)))
  }

  if (identical(method, "GET") && identical(path, "/sbom")) {
    if (!check_permission(principal, "audit_read", throw = FALSE)) {
      return(list(status = 403L, body = list(error = "Forbidden: audit_read required.")))
    }
    return(list(status = 200L, body = server_generate_sbom("dicomtk.server")))
  }

  if (identical(method, "GET") && identical(path, "/threat-model")) {
    if (!check_permission(principal, "audit_read", throw = FALSE)) {
      return(list(status = 403L, body = list(error = "Forbidden: audit_read required.")))
    }
    return(list(status = 200L, body = list(threats = server_threat_model())))
  }

  list(status = 404L, body = list(error = paste("Not found:", method, path)))
}

#' Build a `plumber` REST Router for `dicomtk.server`
#'
#' @param ctx A `"dicom_server_context"` object.
#' @return A `plumber::Plumber` router instance.
#' @export
server_plumber_api <- function(ctx) {
  if (!requireNamespace("plumber", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg plumber} is required to build the REST API.")
  }
  pr <- plumber::pr()
  dispatch <- function(req, res, method, path) {
    hdrs <- as.list(req$HEADERS %||% list())
    body <- if (length(req$postBody) > 0L && nzchar(req$postBody)) {
      tryCatch(jsonlite::fromJSON(req$postBody, simplifyVector = FALSE), error = function(e) list())
    } else {
      list()
    }
    out <- server_handle_request(ctx, method = method, path = path, headers = hdrs, body = body)
    res$status <- out$status
    out$body
  }
  pr$handle("GET", "/health", function(req, res) dispatch(req, res, "GET", "/health"))
  pr$handle("GET", "/projects", function(req, res) dispatch(req, res, "GET", "/projects"))
  pr$handle("POST", "/projects", function(req, res) dispatch(req, res, "POST", "/projects"))
  pr$handle("GET", "/qa", function(req, res) dispatch(req, res, "GET", "/qa"))
  pr$handle("GET", "/audit/verify", function(req, res) dispatch(req, res, "GET", "/audit/verify"))
  pr$handle("GET", "/sbom", function(req, res) dispatch(req, res, "GET", "/sbom"))
  pr$handle("GET", "/threat-model", function(req, res) dispatch(req, res, "GET", "/threat-model"))
  pr
}
