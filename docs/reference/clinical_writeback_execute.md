# Execute Dual-Gated SaMD Clinical Chart Write-Back

Enforces both the server-wide SaMD feature flag
([`clinical_writeback_enabled()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/clinical_writeback_enabled.md))
and RBAC `"clinical_writeback"` permission (`pi` or `admin`) before
dispatching or simulating `STOW-RS` and FHIR `DiagnosticReport` +
`Provenance` write-back, logging every event to the SHA-256 hash-chained
audit trail.

## Usage

``` r
clinical_writeback_execute(
  ctx,
  principal,
  project_id,
  air_bundle,
  dicomweb_stow_url = NULL,
  fhir_base_url = NULL,
  dry_run = FALSE
)
```

## Arguments

- ctx:

  A `"dicom_server_context"` from
  [`server_create_context()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/server_create_context.md).

- principal:

  Authenticated `"dicom_server_principal"`.

- project_id:

  Project identifier.

- air_bundle:

  A `"dicom_ihe_air_bundle"` from
  [`ihe_air_bundle()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/ihe_air_bundle.md).

- dicomweb_stow_url:

  Optional DICOMweb `STOW-RS` endpoint URL.

- fhir_base_url:

  Optional FHIR R4/R5 base URL for `DiagnosticReport` and `Provenance`
  write-back.

- dry_run:

  Logical; if `TRUE`, validates gates and logs audit entry without
  performing external HTTP calls.

## Value

A list with `status`, `study_uid`, `dicom_sop_uid`, and `audit_seq`.
