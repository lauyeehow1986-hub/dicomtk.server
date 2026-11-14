# Approve a Re-Identification Request (Two-Person Broker + DPO Rule)

Requires both an `honest_broker` (`"reid_approve_broker"`) and a
distinct `dpo` (`"reid_approve_dpo"`) principal to approve before
disclosure is unlocked.

## Usage

``` r
reid_approve(enclave, principal, request_id)
```

## Arguments

- enclave:

  A `"dicom_broker_enclave"` object.

- principal:

  Authenticated `"dicom_server_principal"` with `honest_broker` or `dpo`
  role.

- request_id:

  Request identifier returned by
  [`reid_request()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/reid_request.md).

## Value

Updated re-identification request list.
