# dicomtk.server: Multi-User Research Server, Honest Broker Custody & Clinical EHR Integration

`dicomtk.server` (`1.0.0`) is the multi-user governance, honest-broker
custody, and clinical deployment server for
[`dicomtk`](https://lauyeehow1986-hub.github.io/dicomtk/). It provides
8-role OIDC/Keycloak RBAC, a tamper-evident SHA-256 hash-chained JSONL
audit log, a walled-off honest-broker key enclave with two-person
(`honest_broker` + `dpo`) re-identification, `mirai` async QA (`Dice`,
`HD95`, surface `Dice`), MONAI Label active learning, `plumber` REST +
`shiny` clinician portals, **SMART on FHIR v2 EHR-launch (PKCE S256)**,
**IHE AIW-I / AIR**, **dual-gated SaMD clinical write-back**, and
**CycloneDX 1.5 SBOM + STRIDE threat modeling**.

------------------------------------------------------------------------

## Installation

[`install.packages`](https://rdrr.io/r/utils/install.packages.html)`(`` `` ``"dicomtk.server"``,`` `` repos ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(`` `` ``"https://lauyeehow1986-hub.r-universe.dev"``,`` `` ``"https://cloud.r-project.org"`` `` ``)`` ``)`

Or install from GitHub:

`remotes``::`[`install_github`](https://remotes.r-lib.org/reference/install_github.html)`(``"lauyeehow1986-hub/dicomtk.server"``)`

------------------------------------------------------------------------

## How to Use `dicomtk.server`

### 1. 8-Role RBAC & Tamper-Evident Hash-Chained Audit Log

[`library`](https://rdrr.io/r/base/library.html)`(`[`dicomtk.server`](https://lauyeehow1986-hub.github.io/dicomtk.server)`)`` `` ``audit`` ``<-`` ``dicom_audit_log``$``new``(`[`tempfile`](https://rdrr.io/r/base/tempfile.html)`(``fileext ``=`` ``".jsonl"``)``)`` ``rbac`` ``<-`` ``dicom_rbac_policy``$``new``(``)`` `` ``pi_user`` ``<-`` `[`list`](https://rdrr.io/r/base/list.html)`(``user_id ``=`` ``"dr_tan"``, role ``=`` ``"pi"``)`` ``broker_user`` ``<-`` `[`list`](https://rdrr.io/r/base/list.html)`(``user_id ``=`` ``"hb_01"``, role ``=`` ``"honest_broker"``)`` `` ``# RBAC enforces strict separation of duties`` ``rbac``$``check``(``pi_user``, ``"read_deid_cohort"``)`

### 2. Walled-Off Honest-Broker Enclave & Two-Person Re-Identification

`enclave`` ``<-`` ``dicom_broker_enclave``$``new``(``key_secret ``=`` ``"enclave-root-secret"``, audit_log ``=`` ``audit``)`` `` ``# Only 'honest_broker' can ingest raw identifiers into the enclave`` ``enclave``$``ingest_study``(``broker_user``, study_uid ``=`` ``"1.2.840.10008.1"``, patient_id ``=`` ``"P-9001"``)`` `` ``# Two-person (honest_broker + dpo) dual approval required to re-identify a pseudonym`` ``wf`` ``<-`` ``dicom_reid_workflow``$``new``(``enclave ``=`` ``enclave``, audit_log ``=`` ``audit``)`

### 3. SMART on FHIR v2 EHR-Launch (RFC 7636 PKCE S256)

`pkce`` ``<-`` ``smart_pkce_generate``(``)`` ``auth_url`` ``<-`` `[`smart_build_auth_url`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/smart_build_auth_url.md)`(`` `` authorize_endpoint ``=`` ``"https://ehr.hospital.org/oauth2/authorize"``,`` `` client_id ``=`` ``"dicomtk_samd_app"``,`` `` redirect_uri ``=`` ``"https://samd.hospital.org/callback"``,`` `` pkce ``=`` ``pkce``,`` `` launch ``=`` ``"ehr-launch-ctx-123"`` ``)`

### 4. IHE AIW-I Workitems, IHE AIR Bundles & Dual-Gated SaMD Write-Back

`# IHE AIW-I UPS-RS workitem state machine`` ``wi`` ``<-`` ``ihe_aiwi_workitem``$``new``(``study_uid ``=`` ``"1.2.840.10008.1"``, ae_title ``=`` ``"AI_ENGINE"``)`` ``wi``$``claim``(``"AI_ENGINE"``)`` ``wi``$``complete``(``)`` `` ``# Dual-gated clinical write-back: 'final' requires verified_by clinician sign-off`` ``wb`` ``<-`` ``dicom_clinical_writeback``$``new``(``audit_log ``=`` ``audit``)`

### 5. CycloneDX 1.5 SBOM, STRIDE Threat Model & REST / Shiny Server

`sbom`` ``<-`` ``generate_cyclonedx_sbom``(``)`` ``stride`` ``<-`` ``dicom_stride_threat_model``(``)`` `` ``# Launch plumber REST API (/health, /sbom, /threat-model, /audit) or Shiny portal`` ``# dicom_server_app(...)`

### 6. Documentation

Browse the full reference at
<https://lauyeehow1986-hub.github.io/dicomtk.server/>.
