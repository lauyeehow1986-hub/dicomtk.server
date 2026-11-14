# Pull Patient-Context FHIR Resources into the Honest-Broker Enclave

Requires `"deid_ingest"` permission (`coordinator`, `honest_broker`, or
`admin`). Pseudonymizes the EHR `patient_id` inside the walled enclave
crosswalk and returns only de-identified imaging/report counts and UIDs.

## Usage

``` r
smart_pull_patient_context(
  session,
  enclave,
  principal,
  project_id,
  fhir_bundle = NULL
)
```

## Arguments

- session:

  A `"dicom_smart_session"` from
  [`smart_exchange_token()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/smart_exchange_token.md).

- enclave:

  A `"dicom_broker_enclave"` from
  [`broker_enclave_init()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/broker_enclave_init.md).

- principal:

  Authenticated `"dicom_server_principal"`.

- project_id:

  Target project identifier.

- fhir_bundle:

  Optional parsed FHIR Bundle list for offline testing.

## Value

A de-identified summary list containing `project_id`, `pseudonym_id`,
`n_imaging_studies`, `n_diagnostic_reports`, and `study_uids`.
