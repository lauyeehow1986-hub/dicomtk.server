# Create or Open a Hash-Chained JSONL Audit Logger

Initializes a tamper-evident JSON Lines (`.jsonl`) audit log where each
appended entry commits to the cryptographic hash of the previous entry
(`prev_hash` -\> `entry_hash`).

## Usage

``` r
audit_logger(log_path = tempfile("dicomtk_audit_", fileext = ".jsonl"))
```

## Arguments

- log_path:

  Path to the `.jsonl` audit log file.

## Value

An S3 `"dicom_audit_logger"` object.

## Examples

``` r
lp <- tempfile(fileext = ".jsonl")
on.exit(unlink(lp), add = TRUE)
lg <- audit_logger(lp)
audit_append(lg, actor = "coord_1", action = "deid_ingest", project_id = "p1")
#> $seq
#> [1] 1
#> 
#> $timestamp
#> [1] "2026-11-14T15:20:27Z"
#> 
#> $actor
#> [1] "coord_1"
#> 
#> $action
#> [1] "deid_ingest"
#> 
#> $project_id
#> [1] "p1"
#> 
#> $details
#> list()
#> 
#> $prev_hash
#> [1] "0000000000000000000000000000000000000000000000000000000000000000"
#> 
#> $entry_hash
#> [1] "2cc8ab13701fab5967cbd107aa22f329203ba5e2d5df23b001eb25cd268037cd"
#> 
audit_verify(lg)$passed
#> [1] TRUE
```
