# dicomtk.server 0.1.0

* Initial release of the `dicomtk.server` multi-user server and honest-broker custody satellite:
  - Eight-role OpenID Connect / Keycloak RBAC (`pi`, `coordinator`, `annotator`, `auditor`, `admin`, `site_admin`, `honest_broker`, `dpo`).
  - Tamper-evident SHA-256 hash-chained JSONL audit log (`audit_logger()`, `audit_append()`, `audit_verify()`).
  - Walled-off `broker` custody enclave (`broker_enclave_init()`, `broker_deid_study()`) where `pi` provably cannot read key material.
  - Two-person (`honest_broker` + `dpo`) time-limited re-identification workflow (`reid_request()`, `reid_approve()`, `reid_disclose()`).
  - `mirai` async job queue, 3D segmentation QA (`compute_seg_qa()` for `Dice`, `HD95`, and `surface_dice`), MONAI Label active learning, event-driven routing, and `plumber` / `shiny` interfaces.
