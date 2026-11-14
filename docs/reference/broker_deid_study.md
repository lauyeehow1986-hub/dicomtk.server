# De-Identify a Study Inside the Walled Honest-Broker Workspace

Requires `"deid_ingest"` capability (`coordinator`, `honest_broker`, or
`admin`). Executes
[`dicomtk::dicom_deid()`](https://lauyeehow1986-hub.github.io/dicomtk/reference/dicom_deid.html)
using the enclave's sealed key provider, records the reversible
`pseudonym_id -> original_patient_id` mapping inside the enclave
crosswalk, and writes clean de-identified files to `out_dir`.

## Usage

``` r
broker_deid_study(
  enclave,
  principal,
  project_id,
  input_dir,
  out_dir,
  profile = "ps3.15"
)
```

## Arguments

- enclave:

  A `"dicom_broker_enclave"` from
  [`broker_enclave_init()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/broker_enclave_init.md).

- principal:

  Authenticated `"dicom_server_principal"`.

- project_id:

  Target project identifier.

- input_dir:

  Source directory containing identified DICOM files.

- out_dir:

  Output directory in the research project workspace.

- profile:

  Baseline PS3.15 profile name (default `"ps3.15"`).

## Value

A list with `project_id`, `pseudonym_id`, `out_dir`, and `n_files`.
