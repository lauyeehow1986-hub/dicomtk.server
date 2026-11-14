# Changelog

## dicomtk.server 1.0.0

- SMART on FHIR v2 EHR-launch
  ([`smart_discover_config()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/smart_discover_config.md),
  [`smart_pkce_challenge()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/smart_pkce_challenge.md),
  [`smart_build_auth_url()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/smart_build_auth_url.md),
  [`smart_exchange_token()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/smart_exchange_token.md),
  [`smart_pull_patient_context()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/smart_pull_patient_context.md))
  with RFC 7636 S256 PKCE, CSRF state validation, and honest-broker
  enclave pseudonymisation.
- IHE AIW-I UPS-RS workitem state machine
  ([`ihe_aiw_workitem()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/ihe_aiw_workitem.md),
  [`ihe_aiw_transition()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/ihe_aiw_transition.md))
  and IHE AIR conformance bundle
  ([`ihe_air_bundle()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/ihe_air_bundle.md)).
- Dual-gated SaMD clinical write-back
  ([`clinical_writeback_enabled()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/clinical_writeback_enabled.md),
  [`clinical_writeback_execute()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/clinical_writeback_execute.md))
  requiring explicit server opt-in, `"clinical_writeback"` RBAC
  permission, and audit trail logging.
- CycloneDX 1.5 SBOM generator
  ([`server_generate_sbom()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/server_generate_sbom.md)),
  6-category STRIDE threat model
  ([`server_threat_model()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/server_threat_model.md)),
  REST `/sbom` & `/threat-model` endpoints, and non-root
  `inst/docker/Dockerfile`.

## dicomtk.server 0.1.0

- Initial release of the `dicomtk.server` multi-user server and
  honest-broker custody satellite:
  - Eight-role OpenID Connect / Keycloak RBAC (`pi`, `coordinator`,
    `annotator`, `auditor`, `admin`, `site_admin`, `honest_broker`,
    `dpo`).
  - Tamper-evident SHA-256 hash-chained JSONL audit log
    ([`audit_logger()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/audit_logger.md),
    [`audit_append()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/audit_append.md),
    [`audit_verify()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/audit_verify.md)).
  - Walled-off `broker` custody enclave
    ([`broker_enclave_init()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/broker_enclave_init.md),
    [`broker_deid_study()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/broker_deid_study.md))
    where `pi` provably cannot read key material.
  - Two-person (`honest_broker` + `dpo`) time-limited re-identification
    workflow
    ([`reid_request()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/reid_request.md),
    [`reid_approve()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/reid_approve.md),
    [`reid_disclose()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/reid_disclose.md)).
  - `mirai` async job queue, 3D segmentation QA
    ([`compute_seg_qa()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/compute_seg_qa.md)
    for `Dice`, `HD95`, and `surface_dice`), MONAI Label active
    learning, event-driven routing, and `plumber` / `shiny` interfaces.
