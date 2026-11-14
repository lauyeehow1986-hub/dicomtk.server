# Append a Tamper-Evident Entry to the Hash-Chained Audit Log

Append a Tamper-Evident Entry to the Hash-Chained Audit Log

## Usage

``` r
audit_append(logger, actor, action, project_id = NULL, details = list())
```

## Arguments

- logger:

  A `"dicom_audit_logger"` object from
  [`audit_logger()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/audit_logger.md).

- actor:

  Character user/principal identifier.

- action:

  Character action name (e.g., `"deid_ingest"`, `"reid_disclose"`).

- project_id:

  Optional project identifier string.

- details:

  Optional named list of structured event metadata.

## Value

The appended audit record list (including `prev_hash` and `entry_hash`).
