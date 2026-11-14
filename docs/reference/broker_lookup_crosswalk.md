# Guarded Crosswalk Lookup (Rejects All Unapproved or Non-Broker Access)

Guarded Crosswalk Lookup (Rejects All Unapproved or Non-Broker Access)

## Usage

``` r
broker_lookup_crosswalk(enclave, principal, pseudonym_id)
```

## Arguments

- enclave:

  A `"dicom_broker_enclave"` object.

- principal:

  Authenticated `"dicom_server_principal"`.

- pseudonym_id:

  Pseudonym identifier string.

## Value

Never returns for unapproved access; aborts with permission error.
