# Initialize a Walled-Off Honest-Broker Key & Crosswalk Custody Enclave

Creates a `"dicom_broker_enclave"` whose cryptographic master keys,
HashiCorp Vault / KMS credentials, and patient-identity crosswalks live
inside an isolated internal closure inaccessible to `pi`, `coordinator`,
`annotator`, `auditor`, `admin`, and `site_admin` principals.

## Usage

``` r
broker_enclave_init(
  work_dir = tempfile("broker_enclave_"),
  backend = c("local_vault", "hashicorp_vault", "kms"),
  passphrase = NULL,
  vault_url = NULL,
  vault_token = NULL,
  logger = NULL
)
```

## Arguments

- work_dir:

  Walled broker workspace directory.

- backend:

  Key custody backend: `"local_vault"`, `"hashicorp_vault"`, or `"kms"`.

- passphrase:

  Optional passphrase for `"local_vault"` key derivation.

- vault_url:

  Optional HashiCorp Vault / KMS endpoint URL.

- vault_token:

  Optional Vault token (never exposed by `print`/`str`).

- logger:

  Optional `"dicom_audit_logger"` from
  [`audit_logger()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/audit_logger.md).

## Value

An opaque S3 `"dicom_broker_enclave"` handle.
