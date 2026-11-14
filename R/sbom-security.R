#' Generate a CycloneDX 1.5 Software Bill of Materials (SBOM)
#'
#' Inspects the installed or source `DESCRIPTION` of `pkg` and its R package
#' dependencies to emit a CycloneDX 1.5 JSON Software Bill of Materials with
#' `pkg:cran/` Package URLs (`purl`).
#'
#' @param pkg Package name (default `"dicomtk.server"`).
#' @param out_path Optional file path to write the CycloneDX JSON document.
#'
#' @return A list representing the CycloneDX 1.5 BOM.
#' @examples
#' sbom <- server_generate_sbom("dicomtk.server")
#' sbom$bomFormat
#' @export
server_generate_sbom <- function(pkg = "dicomtk.server", out_path = NULL) {
  srv_check_scalar_chr(pkg, "pkg")
  desc <- tryCatch(utils::packageDescription(pkg), error = function(e) NULL)
  if (!is.list(desc) && file.exists("DESCRIPTION")) {
    dcf <- read.dcf("DESCRIPTION")
    desc <- as.list(dcf[1L, ])
  }
  pkg_ver <- as.character(desc$Version %||% "0.1.0")
  raw_deps <- paste(c(desc$Imports %||% "", desc$Suggests %||% ""), collapse = ",")
  deps <- trimws(strsplit(raw_deps, ",", fixed = TRUE)[[1L]])
  deps <- unique(sub("\\s*\\(.*\\)$", "", deps))
  deps <- deps[nzchar(deps) & !(deps %in% c("R", "stats", "utils"))]

  components <- lapply(deps, function(d) {
    d_desc <- tryCatch(utils::packageDescription(d), error = function(e) NULL)
    d_ver <- if (is.list(d_desc) && !is.null(d_desc$Version)) as.character(d_desc$Version) else "unknown"
    list(
      type = "library",
      name = d,
      version = d_ver,
      purl = paste0("pkg:cran/", d, "@", d_ver)
    )
  })

  bom <- list(
    bomFormat = "CycloneDX",
    specVersion = "1.5",
    serialNumber = paste0("urn:uuid:", substr(srv_hash_hex(paste0(pkg, pkg_ver, Sys.time())), 1L, 32L)),
    version = 1L,
    metadata = list(
      timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
      component = list(
        type = "library",
        name = pkg,
        version = pkg_ver,
        purl = paste0("pkg:cran/", pkg, "@", pkg_ver)
      )
    ),
    components = components
  )

  if (!is.null(out_path)) {
    dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
    writeLines(jsonlite::toJSON(bom, auto_unbox = TRUE, pretty = TRUE), out_path)
  }
  bom
}

#' Return the `dicomtk.server` STRIDE Threat Model Matrix
#'
#' Documents security threats, architectural mitigations, and automated
#' verification controls across all six STRIDE categories (`Spoofing`,
#' `Tampering`, `Repudiation`, `Information Disclosure`, `Denial of Service`,
#' and `Elevation of Privilege`).
#'
#' @return A `tibble::tibble` describing the threat model.
#' @examples
#' tm <- server_threat_model()
#' tm$stride_category
#' @export
server_threat_model <- function() {
  tibble::tibble(
    stride_category = c(
      "Spoofing",
      "Tampering",
      "Repudiation",
      "Information Disclosure",
      "Denial of Service",
      "Elevation of Privilege"
    ),
    component = c(
      "OIDC / SMART PKCE Auth",
      "Hash-Chained Audit Log",
      "Two-Person Re-ID & SaMD Write-Back",
      "Honest-Broker Custody Enclave",
      "mirai Job Queue & REST API",
      "8-Role RBAC & SaMD Feature Flag"
    ),
    threat = c(
      "Forged JWTs, alg:none downgrade, or OAuth2 CSRF code interception",
      "Silent deletion or modification of historical audit log entries",
      "Unlogged clinical write-back or unattributed identity disclosure",
      "PI or annotator reading master de-id keys or patient crosswalks",
      "Unbounded synchronous imaging jobs blocking REST/Shiny threads",
      "Cross-project re-ID spoofing or unauthorized clinical chart write-back"
    ),
    mitigation = c(
      "Enforce HS256 header check, non-empty secret, RFC 7636 S256 PKCE, and CSRF state check",
      "SHA-256 prev_hash -> entry_hash chain with monotonic sequence verification",
      "Mandatory audit_append() on all de-id, re-ID, QA, and write-back events",
      "Private closure isolation (.srv_env$enclaves) with sealed print/str methods",
      "Bounded mirai worker pool and explicit status/result polling",
      "Project-scoped RBAC checks, distinct broker+DPO rule, and opt-in SaMD flag"
    ),
    verification = c(
      "test-rbac.R, test-smart-fhir.R",
      "test-audit-projects.R",
      "test-reid-workflow.R, test-clinical-writeback.R",
      "test-broker-enclave.R",
      "test-jobs-qa.R",
      "test-rbac.R, test-reid-workflow.R, test-clinical-writeback.R"
    )
  )
}
