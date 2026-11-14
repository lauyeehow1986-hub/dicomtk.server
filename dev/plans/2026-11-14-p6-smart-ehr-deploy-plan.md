# Phase 6 (`dicomtk.server 1.0.0`) Implementation Plan

## Task 1: SMART on FHIR v2 Discovery, RFC 7636 S256 PKCE & Patient-Context Enclave Pull (`R/smart-fhir.R`)
- **Files**: `R/smart-fhir.R`, `tests/testthat/test-smart-fhir.R`
- **Functions**:
  - `smart_discover_config(fhir_base_url, mock_config = NULL)`
  - `smart_pkce_challenge(verifier = NULL)`
  - `smart_build_auth_url(config, client_id, redirect_uri, launch = NULL, scopes = c("launch", "openid", "fhirUser", "patient/Patient.rs", "patient/ImagingStudy.rs", "patient/DiagnosticReport.rs"), state = NULL, pkce = smart_pkce_challenge())`
  - `smart_exchange_token(config, code, redirect_uri, client_id, code_verifier, expected_state = NULL, received_state = NULL, mock_response = NULL)`
  - `smart_pull_patient_context(session, enclave, principal, project_id, fhir_bundle = NULL)`
- **Verification**: RED -> GREEN `testthat::test_local(filter = "smart-fhir")` testing S256 challenge determinism, CSRF state mismatch rejection, PKCE verifier validation, and enclave-isolated pseudonymisation of pulled FHIR patient context.

## Task 2: IHE AIW-I (UPS-RS Workitem State Machine) & IHE AIR (AI Results Bundle) (`R/ihe-ai.R`)
- **Files**: `R/ihe-ai.R`, `tests/testthat/test-ihe-ai.R`
- **Functions**:
  - `ihe_aiw_workitem(workitem_id, study_uid, model_name, input_series_uid = NULL)`
  - `ihe_aiw_transition(workitem, to_state = c("IN PROGRESS", "COMPLETED", "CANCELED"), performer = NULL, output_refs = list())`
  - `ihe_air_bundle(study_uid, model_name, model_version, dicom_artifact_type = c("SEG", "SR_TID1500"), dicom_sop_uid, fhir_report = list(), uncertainty_summary = list())`
- **Verification**: RED -> GREEN `testthat::test_local(filter = "ihe-ai")` testing illegal transition rejection (`SCHEDULED -> COMPLETED` without `"IN PROGRESS"`) and IHE AIR bundle validation.

## Task 3: Dual-Gated SaMD Clinical Write-Back (`R/clinical-writeback.R`, `R/rbac.R`)
- **Files**: `R/clinical-writeback.R`, `R/rbac.R`, `tests/testthat/test-clinical-writeback.R`
- **Functions**:
  - Add `"clinical_writeback"` capability to `pi` and `admin` in `R/rbac.R`.
  - `clinical_writeback_enabled()`
  - `clinical_writeback_execute(ctx, principal, project_id, air_bundle, dry_run = FALSE)`
- **Verification**: RED -> GREEN `testthat::test_local(filter = "clinical-writeback")` testing that write-back fails when the SaMD feature flag is disabled (even for `admin`), fails when the feature flag is enabled but the principal lacks `"clinical_writeback"` (e.g. `annotator`, `honest_broker`), and succeeds + logs to the hash-chained audit trail when both gates pass.

## Task 4: CycloneDX 1.5 SBOM Generator, STRIDE Threat Model & Production `Dockerfile` (`R/sbom-security.R`, `inst/docker/Dockerfile`)
- **Files**: `R/sbom-security.R`, `inst/docker/Dockerfile`, `tests/testthat/test-sbom-security.R`
- **Functions**:
  - `server_generate_sbom(pkg = "dicomtk.server", out_path = NULL)`
  - `server_threat_model()`
- **Verification**: RED -> GREEN `testthat::test_local(filter = "sbom-security")` verifying CycloneDX 1.5 schema fields, `pkg:cran/...` purls, all 6 STRIDE categories, and presence of `inst/docker/Dockerfile`.

## Task 5: REST API Endpoints (`/smart/launch`, `/writeback`, `/sbom`), Version Bump (`1.0.0`), Vignette & `_pkgdown.yml`
- **Files**: `R/api-plumber.R`, `DESCRIPTION` (`Version: 1.0.0`), `NEWS.md`, `_pkgdown.yml`, `vignettes/honest_broker_and_server.Rmd`
- **Verification**: Update REST endpoints, documentation, and vignette; run `pkgdown::check_pkgdown()` and `testthat::test_local()`.

## Task 6: Full `R CMD check --as-cran --no-manual` Verification
- **Verification**: Run `roxygen2::roxygenise()`, `tools::showNonASCIIfile()`, `devtools::check(..., args = c("--no-manual", "--as-cran"))` -> `0 errors | 0 warnings`.

## Task 7: Final Argon (High) PKCE / SaMD Write-Back Security Audit & `v1.0.0` Release Push
- **Verification**: Switch to **Gemini 4 Argon (High)** for adversarial PKCE/CSRF/SaMD write-back audit, local R library installation, and push `dicomtk.server 1.0.0` to `origin/main`.
