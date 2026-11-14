# Verify Cryptographic Continuity of a Hash-Chained Audit Log

Verify Cryptographic Continuity of a Hash-Chained Audit Log

## Usage

``` r
audit_verify(logger)
```

## Arguments

- logger:

  A `"dicom_audit_logger"` object from
  [`audit_logger()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/audit_logger.md).

## Value

A list with `passed` (logical), `n_entries` (integer), and
`corrupted_line` (`NA_integer_` if valid, or 1-based line index of first
failure).
