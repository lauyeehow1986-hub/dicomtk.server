# Phase 6 (`dicomtk.server 1.0.0`) Design: SMART on FHIR EHR-Launch, Dual-Gated SaMD Write-Back, IHE AIW-I/AIR, SBOM & Threat Model

## 1. Architecture & Scope

`dicomtk.server 1.0.0` completes the hospital EHR integration, IHE radiology AI workflow conformance, and production security/compliance posture of the `dicomtk.server` satellite:

1. **SMART on FHIR v2 EHR-Launch with RFC 7636 S256 PKCE (`R/smart-fhir.R`)**:
   - `smart_discover_config(fhir_base_url, mock_config = NULL)`: Queries `/.well-known/smart-configuration` (or validates a supplied configuration) for `authorization_endpoint`, `token_endpoint`, and `code_challenge_methods_supported` (`"S256"`).
   - `smart_pkce_challenge(verifier = NULL)`: Generates a high-entropy RFC 7636 `code_verifier` (43–128 URL-safe characters) and computes the SHA-256 base64url `code_challenge` (`method = "S256"`).
   - `smart_build_auth_url(config, client_id, redirect_uri, launch = NULL, scopes = ..., state = NULL, pkce = smart_pkce_challenge())`: Builds the EHR-launch authorization URL and returns `list(url, state, pkce)`.
   - `smart_exchange_token(config, code, redirect_uri, client_id, code_verifier, expected_state = NULL, received_state = NULL, mock_response = NULL)`: Verifies CSRF `state`, exchanges the authorization code with `code_verifier`, and returns a `"dicom_smart_session"` containing `access_token`, `patient_id`, `encounter_id`, `fhir_user`, and `scope`.
   - `smart_pull_patient_context(session, enclave, principal, project_id, fhir_bundle = NULL)`: Pulls linked `Patient`, `ImagingStudy`, and `DiagnosticReport` resources for `session$patient_id`, records the reversible `pseudonym_id -> original_patient_id` mapping inside the walled honest-broker enclave (`enclave`), and returns de-identified clinical/imaging summaries to the research workspace.

2. **Dual-Gated SaMD Clinical Write-Back (`R/clinical-writeback.R`)**:
   - Clinical chart write-back (`STOW-RS` `DICOM-SEG` / `SR TID 1500` + FHIR `DiagnosticReport` + `Provenance`) is **disabled by default**.
   - `clinical_writeback_enabled()`: Checks `isTRUE(getOption("dicomtk.server.enable_clinical_writeback", FALSE))` or `tolower(Sys.getenv("DICOMTK_ENABLE_CLINICAL_WRITEBACK")) %in% c("1", "true", "yes")`.
   - `clinical_writeback_execute(ctx, principal, project_id, study_uid, seg_or_sr, diagnostic_report, provenance = NULL, dry_run = FALSE)`:
     - Gate 1: Aborts with a regulatory SaMD safeguard error if `!clinical_writeback_enabled()`.
     - Gate 2: Enforces `check_permission(principal, "clinical_writeback", project_id = project_id, throw = TRUE)` (`pi` or `admin`).
     - Gate 3: Validates IHE AIR artefact completeness and appends a `"clinical_writeback"` entry to the SHA-256 hash-chained audit log.

3. **IHE AIW-I (AI Workflow for Imaging) & AIR (AI Results) (`R/ihe-ai.R`)**:
   - `ihe_aiw_workitem(workitem_id, study_uid, model_name, input_series_uid = NULL)`: Creates a UPS-RS style workitem in `"SCHEDULED"` state.
   - `ihe_aiw_transition(workitem, to_state = c("IN PROGRESS", "COMPLETED", "CANCELED"), performer = NULL, output_refs = list())`: Enforces valid IHE AIW-I state transitions (`SCHEDULED -> IN PROGRESS -> COMPLETED/CANCELED`).
   - `ihe_air_bundle(study_uid, model_name, model_version, dicom_artifact_type = c("SEG", "SR_TID1500"), dicom_sop_uid, fhir_report = list(), uncertainty_summary = list())`: Constructs and validates an IHE AI Results (`AIR`) conformance bundle with embedded FHIR `Provenance`.

4. **CycloneDX 1.5 SBOM, STRIDE Threat Model & Production Container (`R/sbom-security.R`, `inst/docker/Dockerfile`)**:
   - `server_generate_sbom(pkg = "dicomtk.server", out_path = NULL)`: Inspects installed package metadata and dependencies to emit a CycloneDX 1.5 JSON Software Bill of Materials (`bomFormat = "CycloneDX"`, `specVersion = "1.5"`, `components` with `purl = "pkg:cran/..."`).
   - `server_threat_model()`: Returns a structured `tibble` covering all 6 STRIDE categories (`Spoofing`, `Tampering`, `Repudiation`, `Information Disclosure`, `Denial of Service`, `Elevation of Privilege`) mapped to `dicomtk.server` controls and verification tests.
   - `inst/docker/Dockerfile`: Production non-root container specification for `dicomtk.server`.
