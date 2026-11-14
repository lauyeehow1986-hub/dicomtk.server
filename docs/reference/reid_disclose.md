# Disclose Original Patient Identity for an Approved Re-Identification Request

Requires `"reid_disclose"` capability (`honest_broker`), completed
two-person approval, and an unexpired TTL window.

## Usage

``` r
reid_disclose(enclave, principal, request_id)
```

## Arguments

- enclave:

  A `"dicom_broker_enclave"` object.

- principal:

  Authenticated `"dicom_server_principal"` with `honest_broker` role.

- request_id:

  Request identifier returned by
  [`reid_request()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/reid_request.md).

## Value

A list containing `original_patient_id`, `pseudonym_id`, `study_uid`,
and `expires_at`.
