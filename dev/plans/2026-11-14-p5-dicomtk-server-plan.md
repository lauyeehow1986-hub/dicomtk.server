# `dicomtk.server` (`0.1.0`) Phase 5 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans or superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Build `dicomtk.server` (`0.1.0`), the multi-user server satellite package providing 8-role OIDC/Keycloak RBAC, a tamper-evident SHA-256 hash-chained audit trail, a walled-off `broker` key/crosswalk custody enclave with two-person (`honest_broker` + `dpo`) re-identification approval, `mirai` async jobs, 3D clinician QA (`Dice`, `HD95`, `Surface Dice`), MONAI Label active learning, event-driven routing, and `plumber` + `shiny` interfaces.

**Architecture:** Standalone R package at `C:/Users/lauye/.gemini/antigravity/scratch/dicomtk.server` importing `dicomtk (>= 0.5.0)`, `httr2`, `jsonlite`, `tibble`, `cli`, and `rlang`, with `plumber`, `shiny`, `mirai`, and `dicomtk.ai` in `Suggests`. Every security boundary (RBAC, `broker` key isolation, two-person re-ID approval, and hash-chained audit verification) is implemented in pure R/C++ (`dicomtk` SHA-256) and verified via property tests.

**Tech Stack:** R (>= 4.1.0), `dicomtk` (>= 0.5.0), `httr2`, `jsonlite`, `plumber`, `shiny`, `mirai`, `testthat` (>= 3.0.0).

**Effort Routing (`/effort-harness-router`):**
- **Hydrogen (`Medium`)**: Tasks 1–8 (TDD implementation, unit & property tests, vignette & docs).
- **Argon (`High`)**: Task 9 (final adversarial RBAC & honest-broker isolation review, Six-Sigma `R CMD check --as-cran`, GitHub push, and R-universe registration).

---

### Task 1: Package Scaffold, `DESCRIPTION`, `NAMESPACE`, Projects & Hash-Chained Audit Log
**Files:**
- Create: `DESCRIPTION`, `NAMESPACE`, `NEWS.md`, `README.md`, `_pkgdown.yml`
- Create: `R/zzz.R`, `R/utils.R`, `R/audit.R`, `R/projects.R`
- Test: `tests/testthat.R`, `tests/testthat/test-audit-projects.R`

**Steps:**
1. Write failing test `tests/testthat/test-audit-projects.R`:
   - `audit_logger()` appends hash-chained JSONL entries (`prev_hash`, `entry_hash`) and `audit_verify()` returns `passed = TRUE`.
   - Mutating any byte in the JSONL audit file causes `audit_verify()` to return `passed = FALSE` (tamper detection).
   - `project_registry_init()`, `project_create()`, and `project_get()` manage multi-project configurations.
2. Run RED -> implement `DESCRIPTION`, `R/zzz.R`, `R/utils.R`, `R/audit.R`, `R/projects.R` -> run GREEN -> `roxygenise()`, commit.

---

### Task 2: 8-Role OIDC/Keycloak RBAC Engine (`R/rbac.R`)
**Files:**
- Create: `R/rbac.R`
- Test: `tests/testthat/test-rbac.R`

**Steps:**
1. Write failing test `tests/testthat/test-rbac.R`:
   - All 8 roles (`pi`, `coordinator`, `annotator`, `auditor`, `admin`, `site_admin`, `honest_broker`, `dpo`) are recognized.
   - `mint_test_jwt()` and `verify_bearer_token()` round-trip OIDC claims (`sub`, `realm_access$roles`, `exp`) and reject expired or tampered signatures.
   - `check_permission()` enforces the exact capability matrix (e.g., `pi` denied `reid_approve_broker`, `reid_approve_dpo`, `federation_approve`; `site_admin` allowed `federation_approve`; `honest_broker` allowed `reid_approve_broker`).
2. Run RED -> implement `R/rbac.R` -> run GREEN -> `roxygenise()`, commit.

---

### Task 3: Walled-Off `broker` Custody Enclave & `pi` Key-Isolation Property Test (`R/broker-enclave.R`)
**Files:**
- Create: `R/broker-enclave.R`
- Test: `tests/testthat/test-broker-enclave.R`

**Steps:**
1. Write failing test `tests/testthat/test-broker-enclave.R`:
   - `broker_enclave_init()` initializes the walled enclave (`local_vault` or `hashicorp_vault` / `kms`).
   - `broker_deid_study()` de-identifies a synthesized DICOM study (`phi_profile = "basic"`), stores the encrypted `original_patient_id <-> pseudonym_id` mapping inside the enclave, and outputs clean de-identified `.dcm` files.
   - Property test: across 100 randomized inspection/extraction attempts by `pi`, `coordinator`, `annotator`, `auditor`, `admin`, and `site_admin` (`print()`, `format()`, `str()`, `names()`, `$`, `[[`, `as.list()`, `serialize()` inspection, and direct `broker_lookup_crosswalk()` calls), zero secret key bytes and zero unapproved `original_patient_id` strings are ever leaked.
2. Run RED -> implement `R/broker-enclave.R` -> run GREEN -> `roxygenise()`, commit.

---

### Task 4: Two-Person (`honest_broker` + `dpo`) Re-Identification Workflow (`R/reid-workflow.R`)
**Files:**
- Create: `R/reid-workflow.R`
- Test: `tests/testthat/test-reid-workflow.R`

**Steps:**
1. Write failing test `tests/testthat/test-reid-workflow.R`:
   - `reid_request()` creates a `"PENDING"` request with a valid reason code (`"incidental_finding"`).
   - Calling `reid_disclose()` before both approvals aborts (`cli_abort()`).
   - Approving with only `"honest_broker"` keeps status `"PARTIAL_APPROVED"` and `reid_disclose()` still aborts.
   - Self-co-approval by a single user holding both `"honest_broker"` and `"dpo"` roles is rejected (`cli_abort()`).
   - Co-approval by a distinct `"dpo"` principal transitions status to `"APPROVED"`, and `reid_disclose()` returns the single patient mapping (`original_patient_id`) and logs the disclosure in the hash-chained audit trail.
   - Expired disclosure (`ttl_seconds = -1`) is rejected.
2. Run RED -> implement `R/reid-workflow.R` -> run GREEN -> `roxygenise()`, commit.

---

### Task 5: `mirai` Async Job Queue & 3D Clinician QA (`Dice`, `HD95`, `Surface Dice`) (`R/jobs.R`, `R/qa-queue.R`)
**Files:**
- Create: `R/jobs.R`, `R/qa-queue.R`
- Test: `tests/testthat/test-jobs-qa.R`

**Steps:**
1. Write failing test `tests/testthat/test-jobs-qa.R`:
   - `job_queue_init()`, `job_submit()`, `job_status()`, and `job_result()` execute tasks cleanly.
   - `compute_seg_qa()` computes exact `dice = 1.0`, `hd95_mm = 0.0`, `surface_dice = 1.0` for identical 3D masks, and accurate positive `hd95_mm` and reduced `dice`/`surface_dice` for shifted/dilated 3D masks.
   - `qa_enqueue()`, `qa_submit_review()` (requiring `annotator`/`pi`/`admin` role), and `qa_list()` track review status (`"PENDING"`, `"APPROVED"`, `"NEEDS_REVISION"`).
2. Run RED -> implement `R/jobs.R` and `R/qa-queue.R` -> run GREEN -> `roxygenise()`, commit.

---

### Task 6: MONAI Label Active Learning Loop & Event-Driven Routing Engine (`R/active-learning.R`, `R/router.R`)
**Files:**
- Create: `R/active-learning.R`, `R/router.R`
- Test: `tests/testthat/test-active-learning-router.R`

**Steps:**
1. Write failing test `tests/testthat/test-active-learning-router.R`:
   - `active_learning_pool_init()`, `active_learning_add_candidate()`, `active_learning_next()` (selects highest-uncertainty unreviewed study), and `active_learning_submit()` update pool status and log audit events.
   - `routing_rule()` and `routing_execute()` automatically match incoming CT studies, run broker-mode de-identification, run `dicom_image_qc()`, and forward de-identified files to a destination `dicom_connection`.
2. Run RED -> implement `R/active-learning.R` and `R/router.R` -> run GREEN -> `roxygenise()`, commit.

---

### Task 7: REST API Dispatcher (`plumber`) & Clinician Portal (`shiny` + Cornerstone3D/NiiVue) (`R/api-plumber.R`, `R/app-shiny.R`)
**Files:**
- Create: `R/api-plumber.R`, `R/app-shiny.R`
- Test: `tests/testthat/test-api-shiny.R`

**Steps:**
1. Write failing test `tests/testthat/test-api-shiny.R`:
   - `server_create_context()` and `server_handle_request()` handle `/health`, `/projects`, `/deid`, `/reid/request`, `/reid/approve`, `/reid/disclose`, `/qa`, and `/audit/verify` with full RBAC enforcement (401/403 on unauthorized calls, 200 on authorized calls).
   - `server_viewer_html()` generates a self-contained HTML5 Cornerstone3D / NiiVue viewport widget, and `server_shiny_ui()` / `server_shiny_server()` return valid functions/tags.
2. Run RED -> implement `R/api-plumber.R` and `R/app-shiny.R` -> run GREEN -> `roxygenise()`, commit.

---

### Task 8: `dicomtk-lab --profile ttp` Integration, Vignette & `R CMD check` Prep
**Files:**
- Modify: `C:/Users/lauye/.gemini/antigravity/scratch/dicomtk-lab/docker-compose.yml`
- Create: `vignettes/honest_broker_and_server.Rmd`, `tests/testthat/test-ttp-lab.R`

**Steps:**
1. Update `dicomtk-lab/docker-compose.yml` (`ttp` profile with HashiCorp Vault dev container + `honest-broker`).
2. Create `vignettes/honest_broker_and_server.Rmd` walking through all 8 roles, broker de-identification, two-person re-identification approval, 3D QA (`Dice`/`HD95`/`Surface Dice`), and event-driven routing.
3. Run `roxygenise()`, `showNonASCIIfile()`, `checkRd()`, `check_pkgdown()`, `test_local()`, and `R CMD check --as-cran --no-manual`.

---

### Task 9: Final Argon (High) Security & Six-Sigma Review, GitHub Push & R-Universe Registration
**Steps:**
1. Switch to **Gemini 4 Argon (High)** to audit `broker` enclave isolation, RBAC token verification, and two-person approval state transitions.
2. Confirm `0 ERRORs | 0 WARNINGs` on `R CMD check --as-cran --no-manual`, push to `lauyeehow1986-hub/dicomtk.server`, and register `dicomtk.server` in `lauyeehow1986-hub.r-universe.dev/packages.json`.
