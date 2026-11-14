# Initialize an Asynchronous or Synchronous Job Queue

Creates a job queue supporting synchronous in-process execution
(`"sync"`) or non-blocking parallel worker execution via `mirai`
(`"mirai"`).

## Usage

``` r
job_queue_init(backend = c("sync", "mirai"), workers = 2L, logger = NULL)
```

## Arguments

- backend:

  Execution backend: `"sync"` or `"mirai"`.

- workers:

  Number of `mirai` daemon workers when `backend = "mirai"`.

- logger:

  Optional `"dicom_audit_logger"` for job submission auditing.

## Value

An S3 `"dicom_job_queue"` object.

## Examples

``` r
q <- job_queue_init(backend = "sync")
q$backend
#> [1] "sync"
```
