#' Initialize a Multi-Project Server Registry
#'
#' @return An S3 `"dicom_project_registry"` object.
#' @examples
#' reg <- project_registry_init()
#' project_create(reg, "nsclc_01", title = "Lung AI")
#' project_list(reg)
#' @export
project_registry_init <- function() {
  env <- new.env(parent = emptyenv())
  structure(list(store = env), class = "dicom_project_registry")
}

#' Create or Register a Research Imaging Project
#'
#' @param registry A `"dicom_project_registry"` from [project_registry_init()].
#' @param project_id Unique project identifier string.
#' @param title Human-readable project title.
#' @param deid_profile Baseline PS3.15 de-identification profile name
#'   (default `"ps3.15"`).
#' @param custody_mode Key custody mode: `"broker"` (default), `"ttp"`, or `"local"`.
#' @return A list describing the created project.
#' @export
project_create <- function(registry,
                           project_id,
                           title = project_id,
                           deid_profile = "ps3.15",
                           custody_mode = c("broker", "ttp", "local")) {
  if (!inherits(registry, "dicom_project_registry")) {
    cli::cli_abort("{.arg registry} must be a {.cls dicom_project_registry} object.")
  }
  srv_check_scalar_chr(project_id, "project_id")
  custody_mode <- match.arg(custody_mode)

  proj <- list(
    project_id = as.character(project_id),
    title = as.character(title),
    deid_profile = as.character(deid_profile),
    custody_mode = custody_mode,
    created_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  )
  assign(project_id, proj, envir = registry$store)
  proj
}

#' Retrieve a Registered Project
#'
#' @param registry A `"dicom_project_registry"` object.
#' @param project_id Project identifier string.
#' @return The project metadata list.
#' @export
project_get <- function(registry, project_id) {
  if (!inherits(registry, "dicom_project_registry")) {
    cli::cli_abort("{.arg registry} must be a {.cls dicom_project_registry} object.")
  }
  srv_check_scalar_chr(project_id, "project_id")
  if (!exists(project_id, envir = registry$store, inherits = FALSE)) {
    cli::cli_abort("Unknown project {.val {project_id}}.")
  }
  get(project_id, envir = registry$store, inherits = FALSE)
}

#' List Registered Projects
#'
#' @param registry A `"dicom_project_registry"` object.
#' @return A [tibble::tibble] summarizing registered projects.
#' @export
project_list <- function(registry) {
  if (!inherits(registry, "dicom_project_registry")) {
    cli::cli_abort("{.arg registry} must be a {.cls dicom_project_registry} object.")
  }
  keys <- sort(ls(envir = registry$store))
  if (length(keys) == 0L) {
    return(tibble::tibble(
      project_id = character(0), title = character(0),
      deid_profile = character(0), custody_mode = character(0),
      created_at = character(0)
    ))
  }
  rows <- lapply(keys, function(k) {
    p <- get(k, envir = registry$store, inherits = FALSE)
    tibble::tibble(
      project_id = p$project_id,
      title = p$title,
      deid_profile = p$deid_profile,
      custody_mode = p$custody_mode,
      created_at = p$created_at
    )
  })
  do.call(rbind, rows)
}
