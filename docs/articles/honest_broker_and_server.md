# Honest-Broker Custody, Two-Person Re-Identification & Server Workflows

## Overview

`dicomtk.server` provides multi-user research server orchestration and
walled-off honest-broker key custody for clinical DICOM studies:

1.  **8-Role OIDC/Keycloak RBAC**: `pi`, `coordinator`, `annotator`,
    `auditor`, `admin`, `site_admin`, `honest_broker`, and `dpo`.
2.  **SHA-256 Hash-Chained Audit Log**: Every de-identification, re-ID
    request, approval, disclosure, QA review, and job submission is
    appended to a tamper-evident JSONL ledger.
3.  **Walled-Off Custody Enclave**: Master keys and patient-identity
    crosswalks live inside an isolated closure inaccessible to `pi` and
    non-broker roles.
4.  **Two-Person Re-Identification**: Requires distinct `honest_broker`
    and `dpo` principals to approve a request before time-limited
    disclosure.

## Quick Walkthrough

[`library`](https://rdrr.io/r/base/library.html)`(`[`dicomtk.server`](https://lauyeehow1986-hub.github.io/dicomtk.server)`)`` `` ``tmp_dir`` ``<-`` `[`tempfile`](https://rdrr.io/r/base/tempfile.html)`(``"dicomtk_vig_"``)`` ``ctx`` ``<-`` `[`server_create_context`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/server_create_context.md)`(``work_dir ``=`` ``tmp_dir``, jwt_secret ``=`` ``"vignette-secret"``)`` `` ``adm`` ``<-`` `[`server_principal`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/server_principal.md)`(``"adm-1"``, roles ``=`` ``"admin"``, project_ids ``=`` ``"*"``)`` ``pi`` ``<-`` `[`server_principal`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/server_principal.md)`(``"pi-1"``, roles ``=`` ``"pi"``, project_ids ``=`` ``"nsclc-01"``)`` ``hb`` ``<-`` `[`server_principal`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/server_principal.md)`(``"hb-1"``, roles ``=`` ``"honest_broker"``, project_ids ``=`` ``"*"``)`` ``dpo`` ``<-`` `[`server_principal`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/server_principal.md)`(``"dpo-1"``, roles ``=`` ``"dpo"``, project_ids ``=`` ``"*"``)`` `` `[`project_create`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/project_create.md)`(``ctx``$``projects``, ``"nsclc-01"``, title ``=`` ``"NSCLC Radiomics"``)`` ``#> $project_id`` ``#> [1] "nsclc-01"`` ``#> `` ``#> $title`` ``#> [1] "NSCLC Radiomics"`` ``#> `` ``#> $deid_profile`` ``#> [1] "ps3.15"`` ``#> `` ``#> $custody_mode`` ``#> [1] "broker"`` ``#> `` ``#> $created_at`` ``#> [1] "2026-11-14T15:22:17Z"`` `[`project_list`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/project_list.md)`(``ctx``$``projects``)`` ``#> ``# A tibble: 1 × 5`` ``#> project_id title deid_profile custody_mode created_at `` ``#> ``<chr>`` ``<chr>`` ``<chr>`` ``<chr>`` ``<chr>`` `` ``#> ``1`` nsclc-01 NSCLC Radiomics ps3.15 broker 2026-11-14T15:22:17Z`` `` ``# Verify audit chain integrity`` `[`audit_verify`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/audit_verify.md)`(``ctx``$``logger``)`` ``#> $passed`` ``#> [1] TRUE`` ``#> `` ``#> $n_entries`` ``#> [1] 0`` ``#> `` ``#> $corrupted_line`` ``#> [1] NA`` `` `[`unlink`](https://rdrr.io/r/base/unlink.html)`(``tmp_dir``, recursive ``=`` ``TRUE``, force ``=`` ``TRUE``)`
