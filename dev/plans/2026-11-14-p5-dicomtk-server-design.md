# `dicomtk.server` (`0.1.0`) Phase 5 Design Specification

**Date:** 2026-11-14  
**Package:** `dicomtk.server` (`0.1.0`)  
**Repository:** `lauyeehow1986-hub/dicomtk.server`

---

## 1. Architectural Decisions
1. **Standalone Satellite Package**:
   - Imports `dicomtk (>= 0.5.0)`, `httr2`, `jsonlite`, `tibble`, `cli`, `rlang`, `stats`, `utils`.
   - Suggests `dicomtk.ai (>= 0.1.0)`, `plumber (>= 1.2.0)`, `shiny (>= 1.8.0)`, `mirai (>= 1.0.0)`, `DBI (>= 1.2.0)`, `duckdb (>= 1.0.0)`, `testthat (>= 3.0.0)`, `withr`, `knitr`, `rmarkdown`.

2. **8-Role OIDC/Keycloak RBAC & Tamper-Evident Audit Trail (`R/rbac.R`, `R/audit.R`, `R/projects.R`)**:
   - Enforces explicit capabilities across `pi`, `coordinator`, `annotator`, `auditor`, `admin`, `site_admin`, `honest_broker`, and `dpo`.
   - SHA-256 hash-chained JSONL audit log (`audit_logger()`, `audit_append()`, `audit_verify()`).

3. **Walled-Off `broker` Custody Enclave & Two-Person Re-Identification (`R/broker-enclave.R`, `R/reid-workflow.R`)**:
   - Master keys and `pseudonym_id <-> original_patient_id` crosswalks live inside an unexportable closure / HashiCorp Vault KV v2 / KMS enclave.
   - `pi` and all non-broker roles provably cannot read raw keys or bulk crosswalks (`print()`, `format()`, `str()`, `$`, `[[`, and API endpoints all redact/reject).
   - Re-identification (`reid_request() -> reid_approve() -> reid_disclose()`) requires two distinct approvals (`honest_broker` + `dpo` with different `user_id`s) and discloses only the single requested patient mapping within `ttl_seconds`.

4. **Async Jobs, 3D Clinician QA (`Dice`, `HD95`, `Surface Dice`), MONAI Label Active Learning & Event-Driven Routing (`R/jobs.R`, `R/qa-queue.R`, `R/active-learning.R`, `R/router.R`)**:
   - `mirai`-backed job queue with deterministic synchronous fallback.
   - Physical-millimeter 3D `Dice`, `hd95_mm`, and `surface_dice` computation (`compute_seg_qa()`) + clinician review queue.
   - Uncertainty-prioritized active learning (`active_learning_next()`, `active_learning_submit()`).
   - Declarative event-driven routing (`routing_rule()`, `routing_execute()`).

5. **REST API (`plumber`) & Clinician Portal (`shiny`) (`R/api-plumber.R`, `R/app-shiny.R`)**:
   - Pure-R dispatcher `server_handle_request()` mounted by `server_plumber_api()` and `server_shiny_app()` (with Cornerstone3D / NiiVue HTML5 viewer scaffold).
