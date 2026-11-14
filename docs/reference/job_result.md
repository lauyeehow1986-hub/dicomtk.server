# Retrieve Job Result

Retrieve Job Result

## Usage

``` r
job_result(queue, job_id, wait = TRUE)
```

## Arguments

- queue:

  A `"dicom_job_queue"` object.

- job_id:

  Job identifier returned by
  [`job_submit()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/job_submit.md).

- wait:

  Logical; if `TRUE` and backend is `"mirai"`, blocks until completion.

## Value

The return value of the submitted job function.
