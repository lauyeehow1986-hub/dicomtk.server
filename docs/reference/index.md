# Package index

## RBAC & Audit Trail

- [`server_roles()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/server_roles.md)
  :

  List Standard `dicomtk.server` RBAC Roles

- [`server_principal()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/server_principal.md)
  : Construct an Authenticated Server Principal

- [`check_permission()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/check_permission.md)
  : Check Role-Based Access Permission for a Principal

- [`mint_test_jwt()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/mint_test_jwt.md)
  : Mint a Signed Local Test OIDC JWT Token

- [`verify_bearer_token()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/verify_bearer_token.md)
  : Verify an OIDC / Keycloak Bearer Token and Return a Server Principal

- [`audit_logger()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/audit_logger.md)
  : Create or Open a Hash-Chained JSONL Audit Logger

- [`audit_append()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/audit_append.md)
  : Append a Tamper-Evident Entry to the Hash-Chained Audit Log

- [`audit_verify()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/audit_verify.md)
  : Verify Cryptographic Continuity of a Hash-Chained Audit Log

- [`project_registry_init()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/project_registry_init.md)
  : Initialize a Multi-Project Server Registry

- [`project_create()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/project_create.md)
  : Create or Register a Research Imaging Project

- [`project_get()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/project_get.md)
  : Retrieve a Registered Project

- [`project_list()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/project_list.md)
  : List Registered Projects

## Honest-Broker Custody & Two-Person Re-Identification

- [`broker_enclave_init()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/broker_enclave_init.md)
  : Initialize a Walled-Off Honest-Broker Key & Crosswalk Custody
  Enclave
- [`broker_deid_study()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/broker_deid_study.md)
  : De-Identify a Study Inside the Walled Honest-Broker Workspace
- [`broker_lookup_crosswalk()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/broker_lookup_crosswalk.md)
  : Guarded Crosswalk Lookup (Rejects All Unapproved or Non-Broker
  Access)
- [`reid_request()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/reid_request.md)
  : Request Two-Person Re-Identification of a Pseudonymized Study
- [`reid_approve()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/reid_approve.md)
  : Approve a Re-Identification Request (Two-Person Broker + DPO Rule)
- [`reid_disclose()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/reid_disclose.md)
  : Disclose Original Patient Identity for an Approved Re-Identification
  Request

## Async Jobs, Segmentation QA & Active Learning

- [`job_queue_init()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/job_queue_init.md)
  : Initialize an Asynchronous or Synchronous Job Queue
- [`job_submit()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/job_submit.md)
  : Submit a Job to the Server Job Queue
- [`job_status()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/job_status.md)
  : Query Job Status
- [`job_result()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/job_result.md)
  : Retrieve Job Result
- [`compute_seg_qa()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/compute_seg_qa.md)
  : Compute 3D Segmentation QA Metrics (Dice, HD95, Surface Dice)
- [`qa_queue_init()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/qa_queue_init.md)
  : Initialize a QA Review Queue
- [`qa_enqueue()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/qa_enqueue.md)
  : Enqueue a Study or Segmentation into the QA Review Queue
- [`qa_submit_review()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/qa_submit_review.md)
  : Submit a QA Review Decision
- [`qa_list()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/qa_list.md)
  : List QA Queue Items
- [`active_learning_pool_init()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/active_learning_pool_init.md)
  : Initialize a MONAI Label / Active Learning Candidate Pool
- [`active_learning_add_candidate()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/active_learning_add_candidate.md)
  : Add an Unlabeled Study Candidate to the Active Learning Pool
- [`active_learning_next()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/active_learning_next.md)
  : Select Next Candidate(s) for Annotation
- [`active_learning_submit()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/active_learning_submit.md)
  : Submit a Completed Annotation Label to the Active Learning Pool

## Event Routing, REST API & Shiny Portal

- [`routing_rule()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/routing_rule.md)
  : Define an Event-Driven Study Routing Rule

- [`routing_execute()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/routing_execute.md)
  : Execute Matching Event-Driven Routing Rules

- [`server_create_context()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/server_create_context.md)
  :

  Create a Multi-User `dicomtk.server` Runtime Context

- [`server_handle_request()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/server_handle_request.md)
  :

  Dispatch an HTTP-Style Request Against a `dicom_server_context`

- [`server_plumber_api()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/server_plumber_api.md)
  :

  Build a `plumber` REST Router for `dicomtk.server`

- [`server_viewer_html()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/server_viewer_html.md)
  : Generate an HTML5 Zero-Footprint Medical Imaging Viewer Scaffold

- [`server_shiny_ui()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/server_shiny_ui.md)
  :

  Build the `shiny` Portal UI for `dicomtk.server`

- [`server_shiny_server()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/server_shiny_server.md)
  :

  Build the `shiny` Server Function for `dicomtk.server`

## SMART on FHIR, IHE AI & Security

- [`smart_discover_config()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/smart_discover_config.md)
  : Discover SMART on FHIR v2 Configuration

- [`smart_pkce_challenge()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/smart_pkce_challenge.md)
  : Generate an RFC 7636 S256 PKCE Verifier and Challenge Pair

- [`smart_build_auth_url()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/smart_build_auth_url.md)
  : Build a SMART on FHIR v2 EHR-Launch Authorization URL

- [`smart_exchange_token()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/smart_exchange_token.md)
  : Exchange a SMART Authorization Code for a Patient-Context Session

- [`smart_pull_patient_context()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/smart_pull_patient_context.md)
  : Pull Patient-Context FHIR Resources into the Honest-Broker Enclave

- [`ihe_aiw_workitem()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/ihe_aiw_workitem.md)
  : Create an IHE AIW-I (AI Workflow for Imaging) UPS-RS Workitem

- [`ihe_aiw_transition()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/ihe_aiw_transition.md)
  : Transition an IHE AIW-I Workitem State

- [`ihe_air_bundle()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/ihe_air_bundle.md)
  : Construct and Validate an IHE AIR (AI Results) Conformance Bundle

- [`clinical_writeback_enabled()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/clinical_writeback_enabled.md)
  : Check Whether SaMD Clinical Chart Write-Back Is Explicitly Enabled

- [`clinical_writeback_execute()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/clinical_writeback_execute.md)
  : Execute Dual-Gated SaMD Clinical Chart Write-Back

- [`server_generate_sbom()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/server_generate_sbom.md)
  : Generate a CycloneDX 1.5 Software Bill of Materials (SBOM)

- [`server_threat_model()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/server_threat_model.md)
  :

  Return the `dicomtk.server` STRIDE Threat Model Matrix
