# dicomtk.server 1.0.0

* SMART on FHIR v2 EHR-launch (`smart_discover_config()`, `smart_pkce_challenge()`, `smart_build_auth_url()`, `smart_exchange_token()`, `smart_pull_patient_context()`) with RFC 7636 S256 PKCE, CSRF state validation, and honest-broker enclave pseudonymisation.
* IHE AIW-I UPS-RS workitem state machine (`ihe_aiw_workitem()`, `ihe_aiw_transition()`) and IHE AIR conformance bundle (`ihe_air_bundle()`).
* Dual-gated SaMD clinical write-back (`clinical_writeback_enabled()`, `clinical_writeback_execute()`) requiring explicit server opt-in, `"clinical_writeback"` RBAC permission, and audit trail logging.
* CycloneDX 1.5 SBOM generator (`server_generate_sbom()`), 6-category STRIDE threat model (`server_threat_model()`), REST `/sbom` & `/threat-model` endpoints, and non-root `inst/docker/Dockerfile`.

# dicomtk.server 0.1.0

* Initial release of the `dicomtk.server` multi-user server and honest-broker custody satellite:
  - Eight-role OpenID Connect / Keycloak RBAC (`pi`, `coordinator`, `annotator`, `auditor`, `admin`, `site_admin`, `honest_broker`, `dpo`).
  - Tamper-evident SHA-256 hash-chained JSONL audit log (`audit_logger()`, `audit_append()`, `audit_verify()`).
  - Walled-off `broker` custody enclave (`broker_enclave_init()`, `broker_deid_study()`) where `pi` provably cannot read key material.
  - Two-person (`honest_broker` + `dpo`) time-limited re-identification workflow (`reid_request()`, `reid_approve()`, `reid_disclose()`).
  - `mirai` async job queue, 3D segmentation QA (`compute_seg_qa()` for `Dice`, `HD95`, and `surface_dice`), MONAI Label active learning, event-driven routing, and `plumber` / `shiny` interfaces.
