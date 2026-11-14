# Request Two-Person Re-Identification of a Pseudonymized Study

Requires `"reid_request"` capability (`pi`, `coordinator`, or
`honest_broker`). Records a pending re-identification request inside the
walled honest-broker enclave.

## Usage

``` r
reid_request(
  enclave,
  principal,
  project_id,
  pseudonym_id,
  reason,
  ttl_seconds = 3600L
)
```

## Arguments

- enclave:

  A `"dicom_broker_enclave"` object.

- principal:

  Authenticated `"dicom_server_principal"`.

- project_id:

  Project identifier matching the pseudonymized study.

- pseudonym_id:

  Pseudonym identifier recorded in the enclave crosswalk.

- reason:

  Clinical or regulatory justification string.

- ttl_seconds:

  Time-to-live in seconds once both approvals complete (default
  `3600L`).

## Value

A list describing the pending re-identification request.
