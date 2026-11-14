# Query Job Status

Query Job Status

## Usage

``` r
job_status(queue, job_id)
```

## Arguments

- queue:

  A `"dicom_job_queue"` object.

- job_id:

  Job identifier returned by
  [`job_submit()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/job_submit.md).

## Value

A list with `job_id`, `project_id`, `job_type`, and `status`.
